//
//  FirebaseUtilities.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/23/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

import GoogleSignIn
import FBSDKLoginKit

class FirebaseUtilities {
    
    private static let database = Firestore.firestore()
    
    // MARK: - Sign Up/Login
    
    static func createUserWithGoogle(credential: AuthCredential!, user: GIDGoogleUser!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().signIn(with: credential) { (result, err) in
            if err != nil {
                print("Error signing into firebase after google login: ", err!)
                return
            }
            guard let uid = result?.user.uid else { return }
            if result!.additionalUserInfo!.isNewUser == true {
                let database = Firestore.firestore()
                let fullName = user.profile.name
                let username = (user.profile.name!).replacingOccurrences(of: " ", with: "").lowercased()
                let firstName = user.profile.givenName
                let lastName = user.profile.familyName
                let email = user.profile.email
                database.collection("users").document(uid).setData(["username": username, "email": email!, "uid": result!.user.uid, "full_name": fullName!, "first_name": firstName!, "last_name": lastName!])
                database.collection("usernames").document(username).setData(["email": email!])
            }
            return completion(nil)
        }
    }
    
    static func createUserWithPhone(credential: AuthCredential!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().signIn(with: credential) { (authDataResult, error) in
            if error != nil {
                return completion(error!)
            }
            if authDataResult!.additionalUserInfo!.isNewUser {
                let uid = authDataResult!.user.uid
                self.createUsername(email: "user", appendedNumbersCount: 2) { (username, error) in
                    if error != nil {
                        return completion(error!)
                    }
                    let data: [String: Any] = ["uid": uid, "username": username!, "full_name": username!] // TODO: add phone number to data
                    Firestore.firestore().collection("users").document(uid).setData(data)
                    return completion(nil)
                }
            }
        }
    }
    
    static func createUserWithEmail(email: String!, password: String!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if error != nil {
                return completion(error!)
            } else {
                let database = Firestore.firestore()
                let uid = result!.user.uid
                FirebaseUtilities.createUsername(email: email, appendedNumbersCount: 2) { (username, usernameError) in
                    if usernameError != nil {
                        return completion(usernameError!)
                    }
                    database.collection("users").document(uid).setData(["username": username!, "email": email ?? "", "uid": result!.user.uid])
                    return completion(nil)
                }
            }
        }
    }
    
    static func handleFacebookSignUp(viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        LoginManager().logIn(permissions: ["email", "public_profile"], from: viewController.self) { (result, permissionError) in
            if permissionError != nil {
                return completion(permissionError!)
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
            Auth.auth().signIn(with: credential) { (res, signInError) in
                if signInError != nil {
                    return completion(signInError!)
                }
                if res!.additionalUserInfo!.isNewUser {
                    let graphRequestConnection = GraphRequestConnection()
                    let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, first_name, last_name"], tokenString: AccessToken.current?.tokenString, version: Settings.defaultGraphAPIVersion , httpMethod: .get)
                    graphRequestConnection.add(graphRequest) { (httpResponse, result, error) in
                        
                        if error != nil {
                            return completion(error!)
                        }
                        if let result = result as? [String:Any] {
                            let database = Firestore.firestore()
                            let uid = res!.user.uid
                            let username: String = (result["name"] as! String).lowercased().replacingOccurrences(of: " ", with: "")
                            let email: String = result["email"] as! String
                            let firstName: String = result["first_name"] as! String
                            let lastName: String = result["last_name"] as! String
                            let fullName: String = result["name"] as! String
                            
                            database.collection("users").document(uid).setData(["username": username, "email": email, "uid": res!.user.uid, "first_name": firstName, "last_name": lastName, "full_name": fullName])
                            return completion(nil)
                        }
                    }
                    graphRequestConnection.start()
                } else {
                    return completion(nil)
                }
            }
        }
    }
    
    // creates a username, then checks to make sure that no other user has used that username
    static func createUsername(email: String!, appendedNumbersCount: Int!, completion: @escaping(_ username: String?, _ error: Error?) -> Void) {
        let emailComponents = email.components(separatedBy: "@")
        var username = emailComponents[0]
        
        let docRef = database.collection("usernames").document(username)
        docRef.getDocument { (document, error) in
            if error != nil {
                return completion(nil, error)
            }
            if let document = document, document.exists {
                let bottomLimit = Int(pow(Double(10), Double(appendedNumbersCount - 1))) // raising 10 to the number of specified appended numbers (-1). casts are necessary
                let upperLimit = Int(pow(Double(10), Double(appendedNumbersCount)))
                let number = Int.random(in: bottomLimit..<upperLimit)
                username = username + "\(number)"
                
                createUsername(email: username, appendedNumbersCount: (1)) { (username, error) in
                    completion(username, error)
                } // recursive, continues calling function until correct username, then returns in completion
            } else {
                return completion(username, nil)
            }
        }
    }
    
    // MARK: - Post Interaction
    
    static func likePost(uid: String!, postID: String!, creatoruid: String!, thumbnailPictureURL: String!, completion: @escaping(_ error: Error?) -> Void) {
        let batch = database.batch()
        
        let postStorageRef = database.collection("posts").document(postID)
        batch.updateData(["like_count": FieldValue.increment(Int64(1))], forDocument: postStorageRef)
        
        let postLikersDoc = postStorageRef.collection("post_likers").document(uid)
        batch.setData(["uid": uid!], forDocument: postLikersDoc)
        
        let likedPostsDoc = database.collection("users").document(uid).collection("liked_posts").document(postID)
        batch.setData(["post_ID": postID!], forDocument: likedPostsDoc)
        
        database.collection("users").document(uid).getDocument { (snapshot, error) in
            if error != nil {
                return completion(error!)
            }
            let data = snapshot?.data()
            let profilePictureURL = data!["profile_image"] as? String ?? ""
            let username = data!["username"] as? String ?? ""
            
            let docID = postID + "_" + uid
            let activityDoc = self.database.collection("users").document(creatoruid!).collection("activity").document(docID)
            let profileObject = ["profile_picture_URL": profilePictureURL, "uid": uid, "username": username]
            batch.setData(["profile": profileObject, "timestamp": Timestamp.init(), "type": "like", "thumbnail_picture_URL": thumbnailPictureURL!], forDocument: activityDoc)
            
            batch.commit { (error) in
                if error != nil {
                    return completion(error!)
                }
            }
        }
    }
    
    static func unlikePost(uid: String!, postID: String!, creatoruid: String!, completion: @escaping(_ error: Error?) -> Void) {
        
        let batch = database.batch()
        
        let postStorageRef = database.collection("posts").document(postID)
        batch.updateData(["like_count": FieldValue.increment(Int64(-1))], forDocument: postStorageRef)
        
        let postLikersDoc = postStorageRef.collection("post_likers").document(uid)
        batch.deleteDocument(postLikersDoc)
        
        let likedPostsDoc = database.collection("users").document(uid).collection("liked_posts").document(postID)
        batch.deleteDocument(likedPostsDoc)
        
        let docID = postID + "_" + uid
        let activityDoc = self.database.collection("users").document(creatoruid!).collection("activity").document(docID)
        batch.deleteDocument(activityDoc)
        
        batch.commit { (error) in
            if error != nil {
                return completion(error!)
            }
        }
    }
    
    // MARK: - Update User Data
    
    static func reauthenticatePasswordUser(email: String!, password: String!, completion: @escaping(_ error: Error?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        currentUser.reauthenticate(with: credential) { (result, error) in
            if error != nil {
                return completion(error!)
            } else {
                return completion(nil)
            }
        }
    }
    
    private static func reauthenticateFacebookUser(user: User!, viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.authType = .reauthorize
        loginManager.logIn(permissions: [], from: viewController.self) { (result, error) in
            if error != nil {
                return completion(error!)
            } else {
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                user.reauthenticate(with: credential) { (result, error) in
                    if error != nil {
                        return completion(error!)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    static func reauthenticateUser(currentUser: User, viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let providerID = currentUser.providerData[0].providerID
        for provider in currentUser.providerData {
            print("Provider ID:", provider.providerID)
        }
        
        switch providerID {     // email has own function bc needs password
        case "facebook.com":
            reauthenticateFacebookUser(user: currentUser, viewController: viewController) { (error) in
                if error != nil {
                    return completion(error!)
                }
                return completion(nil)
            }
        case "google.com":  // must make viewController a GIDSignInDelegate and do most work from there
            GIDSignIn.sharedInstance()?.signIn()
            return completion(nil)
        case "phone":   // TODO: Reauthenticate phone users
            break
        default:
            break
        }
    }
    
    static func updateUserEmail(user: User, newEmail: String, completion: @escaping(_ error: Error?) -> Void) {
        user.updateEmail(to: newEmail) { (updateEmailerror) in
            if updateEmailerror != nil {
                return completion(updateEmailerror!)
            }
            database.collection("users").document(user.uid).updateData(["email": newEmail]) { (error) in
                if error != nil {
                    return completion(error)
                }
                return completion(nil)
            }
        }
    }
    
    static func linkEmailToAccount(currentUser: User, email: String, password: String, completion: @escaping(_ error: Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        currentUser.link(with: credential) { (result, error) in
            if error != nil {
                return completion(error!)
            } else {
                database.collection("users").document(currentUser.uid).updateData(["email": email]) { (dataError) in
                    if error != nil {
                        return completion(dataError!)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    static func linkFacebookToAccount(user: User, viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.authType = .reauthorize
        loginManager.logIn(permissions: [], from: viewController.self) { (result, error) in
            if error != nil {
                return completion(error!)
            } else {
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                user.link(with: credential) { (result, linkError) in
                    if error != nil {
                        return completion(linkError!)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    static func updateUserProfileData(userProperty: String!, oldData: String!, newData: String!, completion: @escaping(_ error: Error?) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        let userDocRef = database.collection("users").document(uid)
        
        guard let newData = newData else { return }
        
        switch userProperty {
        case "Name":
            userDocRef.setData(["full_name": newData], merge: true)
        case "Username":
            let batch = database.batch()
            
            // update username in user document
            batch.updateData(["username": newData], forDocument: userDocRef)
            
            let usernameEmailPath = database.collection("usernames").document(oldData)
            usernameEmailPath.getDocument { (usernameEmailDoc, usernameEmailError) in
                guard let data = usernameEmailDoc?.data() else { return }
                let email = data["email"] as? String ?? ""
                // create new username/email doc
                let newUsernameEmailPath = database.collection("usernames").document(newData)
                batch.setData(["email": email], forDocument: newUsernameEmailPath)
                
                // delete old username in username-email
                batch.deleteDocument(usernameEmailPath)
                
                // change username on all the users posts
                userDocRef.collection("posts").getDocuments { (snapshot, error) in
                    if error != nil {
                        return completion(error!)
                    }
                    guard let unwrappedSnapshot = snapshot else { return }
                    let documents = unwrappedSnapshot.documents
                    
                    for document in documents {
                        let postID = document.documentID
                        let postPath = database.collection("posts").document(postID)
                        batch.updateData(["creator.username": newData], forDocument: postPath)
                    }
                    
                    batch.commit { (batchError) in
                        if batchError != nil {
                            return completion(batchError!)
                        }
                    }
                }
            }
            
        case "Bio":
            // change bio in user document or set it if none yet set
            userDocRef.setData(["bio": newData], merge: true)
            return completion(nil)
        default:
            print("went through to default:", userProperty!)
            // TODO: Show error
        }
    }
    
    // MARK: - User Interaction
    
    static func followUser(uid: String!, uidToFollow: String!, completion: @escaping(_ error: Error?) -> Void) {
        let batch = database.batch()
        
        getUsername(uid: uid) { (username, error) in
            if error != nil {
                return completion(error!)
            } else {
                
                // update relationship in relationships collection
                let relationshipDocPath = database.collection("relationships").document("\(uid!)_\(uidToFollow!)")
                batch.setData(["follower_uid": uid!, "following_uid": uidToFollow!, "follower_username": username!], forDocument: relationshipDocPath)
                
                // add 1 to current user's following count
                let userDocPath = database.collection("users").document(uid)
                batch.updateData(["following_count": FieldValue.increment(Int64(1))], forDocument: userDocPath)
                
                // add 1 to the follower count of the user whose profile it is
                let followingUserDocPath = database.collection("users").document(uidToFollow)
                batch.updateData(["follower_count": FieldValue.increment(Int64(1))], forDocument: followingUserDocPath)
                
                // add the uid of profile user to the subcollection of following uids in current user's document
                let followinguidPath = userDocPath.collection("following").document(uidToFollow)
                batch.setData(["following_uid": uidToFollow!], forDocument: followinguidPath)
                
                // add the profile user's post ids to the current user's subcollection of post ids
                getPostIDs(userID: uidToFollow, collection: "posts") { (postIDs, error) in
                    if error != nil {
                        return completion(error!)
                    }
                    for postID in postIDs! {
                        let followingPostIDsPath = userDocPath.collection("following_post_IDs").document(postID)
                        batch.setData(["following_uid": uidToFollow!], forDocument: followingPostIDsPath)
                    }
                    
                    batch.commit { (error) in
                        if error != nil {
                            return completion(error!)
                        }
                        return completion(nil)
                    }
                }
            }
        }
    }
    
    static func unfollowerUser(uid: String!, uidToUnfollow: String!, completion: @escaping(_ error: Error?) -> Void) {
        let batch = database.batch()
        
        // delete the relationship in the relationships collection
        let relationshipDocPath = database.collection("relationships").document("\(uid!)_\(uidToUnfollow!)")
        batch.deleteDocument(relationshipDocPath)
        
        // subtract 1 from current user's following count
        let userDocPath = database.collection("users").document(uid)
        batch.updateData(["following_count": FieldValue.increment(Int64(-1))], forDocument: userDocPath)
        
        // subtract 1 from the follower count of the user whose profile it is
        let followingUserDocPath = database.collection("users").document(uidToUnfollow)
        batch.updateData(["follower_count": FieldValue.increment(Int64(-1))], forDocument: followingUserDocPath)
        
        // delete the uid of profile user from the subcollection of following uids in current user's document
        let followinguidPath = userDocPath.collection("following").document(uidToUnfollow)
        batch.deleteDocument(followinguidPath)
        
        // delete the profile user's post ids from the current user's subcollection of post ids
        // not the best, but should work for now
        getPostIDs(userID: uidToUnfollow, collection: "posts") { (postIDs, error) in
            if error != nil {
                return completion(error!)
            }
            for postID in postIDs! {
                let followingPostIDsPath = userDocPath.collection("following_post_IDs").document(postID)
                batch.deleteDocument(followingPostIDsPath)
            }
            
            batch.commit { (error) in
                if error != nil {
                    return completion(error!)
                }
            }
        }
    }
    
    static func getUsername(uid: String, completion: @escaping(_ username:String?, _ error: Error?) -> Void) {
        database.collection("users").document(uid).getDocument { (snapshot, error) in
            if error != nil {
                return completion(nil, error!)
            }
            guard let documentData = snapshot?.data() else { return completion(nil, "There is no user corresponding to that identifier." as? Error) }
            let username = documentData["username"] as? String ?? ""
            return completion(username, nil)
        }
    }
    
    // MARK: - Profile Navigation
    
    static func checkIfFollowing(followeruid: String!, followinguid: String?, completion: @escaping(_ isFollowing:Bool?, _ error: Error?) -> Void) {
        guard let followinguid = followinguid else { return }
        database.collection("relationships").document("\(followeruid!)_\(followinguid)").getDocument { (document, error) in
            if error != nil {
                return completion(nil, error!)
            }
            if document!.exists {
                return completion(true, nil)
            } else {
                return completion(false, nil)
            }
        }
    }
    
    // MARK: - Post Generation
    
    // Check if a user has liked a post given the post ID, returns the boolean in the completion block
    static func checkIfLiked(uid: String, postID: String, completion: @escaping(_ isLiked:Bool?, _ error: Error?) -> Void) {
        database.collection("posts").document(postID).collection("post_likers").document(uid).getDocument { (document, error) in
            if error != nil {
                return completion(nil, error!)
            }
            if document!.exists {
                return completion(true, nil)
            } else {
                return completion(false, nil)
            }
        }
    }
    
    // the collection could be liked_posts, following_post_IDs, or posts
    static func getPostIDs(userID: String!, collection: String!, completion: @escaping(_ postIDs:[String]?, _ error: Error?) -> Void) {
        self.database.collection("users").document(userID).collection(collection).getDocuments { (snapshot, error) in
            if error != nil {
                return completion(nil, error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var postIDs = [String]()
            
            for document in documents {
                
                let id = document.documentID
                
                postIDs.append(id)
            }
            return completion(postIDs, nil)
        }
    }
    
    static func getUserPostPreviews(profileuid: String!, completion: @escaping(_ newPostPreviews:[PostPreview]?, _ error: Error?) -> ()) {
        database.collection("users").document(profileuid).collection("posts").getDocuments { (snapshot, error) in
            if error != nil {
                return completion(nil, error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var postPreviews = [PostPreview]()
            for document in documents {
                let documentData = document.data()
                
                let id = document.documentID
                let thumbnail = documentData["thumbnail_image"] as? String ?? ""
                
                let postPreview = PostPreview(postID: id, thumbnailImageURL: thumbnail)
                postPreviews.append(postPreview)
            }
            return completion(postPreviews, nil)
        }
    }
    
    static func getExplorePostPreviews(completion: @escaping(_ newPostPreviews:[PostPreview]?, _ error: Error?) -> ()) {
        let postsRef = self.database.collection("posts")
        var queryRef: Query
        
        queryRef = postsRef.limit(to: 9)
        
        queryRef.getDocuments { (snapshot, error) in
            if error != nil {
                return completion(nil, error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var tempPostPreviews = [PostPreview]()
            for document in documents {
                let documentData = document.data()
                
                let id = document.documentID
                let thumbnail = documentData["thumbnail_image"] as? String ?? ""
                
                let postPreview = PostPreview(postID: id, thumbnailImageURL: thumbnail)
                tempPostPreviews.append(postPreview)
            }
            return completion(tempPostPreviews, nil)
        }
    }
    
    // given a set of postIDs, it returns n more posts on the first call, then n more posts.
    static func fetchPosts(postIDs: [String], lastPost: Post?, postsToLoadInitial: Int, postsToLoad: Int, completion: @escaping(_ posts:[Post]?, _ error: Error?) -> ()) {
        
        if !postIDs.isEmpty {
            
            let postsRef = self.database.collection("posts").whereField("post_ID", in: postIDs)
            let lastPost = lastPost
            var queryRef: Query
            
            if lastPost == nil {
                queryRef = postsRef.order(by: "timestamp", descending: true).limit(to: postsToLoadInitial)
            } else {
                let lastTimestamp = lastPost!.timestamp
                queryRef = postsRef.order(by: "timestamp", descending: true).start(after: [lastTimestamp]).limit(to: postsToLoad)
            }
            
            queryRef.getDocuments { (snapshot, error) in
                if error != nil {
                    return completion(nil, error!)
                }
                guard let unwrappedSnapshot = snapshot else { return }
                let documents = unwrappedSnapshot.documents
                
                var tempPosts = [Post]()
                
                for document in documents {
                    let documentData = document.data()
                    
                    let postID = documentData["post_ID"] as? String ?? ""
                    let dareID = documentData["dare_ID"] as? String ?? ""
                    
                    let timestamp = documentData["timestamp"] as! Timestamp? ?? Timestamp(date: Date(timeIntervalSince1970: 0))
                    let timestampDate = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
                    
                    let pathToVideo = documentData["video_URL"] as? String ?? ""
                    
                    let caption = documentData["caption"] as? String ?? ""
                    let dareFullName = documentData["dare_full_name"] as? String ?? ""
                    
                    let creatorData = documentData["creator"] as? [String: Any] ?? ["": ""]
                    let creatoruid = creatorData["uid"] as? String ?? ""
                    let pathToProfileImage = creatorData["profile_picture_URL"] as? String ?? ""
                    let creatorUsername = creatorData["username"] as? String ?? ""
                    
                    let numberOfLikes = documentData["like_count"] as? Int ?? 0
                    let numberOfComments = documentData["comment_count"] as? Int ?? 0
                    
                    let pathToThumbnail = documentData["thumbnail_image"] as? String ?? ""
                    
                    let post = Post(postID: postID, creatoruid: creatoruid, dareID: dareID, pathToVideo: pathToVideo, timestamp: timestampDate, pathToProfileImage: pathToProfileImage, creatorUsername: creatorUsername, caption: caption, dareFullName: dareFullName, numberOfLikes: numberOfLikes, numberOfComments: numberOfComments)
                    post.pathToThumbnail = pathToThumbnail
                    tempPosts.append(post)
                }
                return completion(tempPosts, nil)
            }
        }
    }
    
    // MARK: - Dare Creation
    
    static func createDare(dareTitle: String, completion: @escaping(_ error: Error?) -> Void) {
        let trimmedTitle = dareTitle.replacingOccurrences(of: " ", with: "")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        database.collection("users").document(uid).getDocument { (snapshot, error) in
            if error != nil {
                return completion(error!)
            }
            guard let documentData = snapshot?.data() else { return }
            let profilePictureURL = documentData["profile_image"] as? String ?? ""
            let username = documentData["username"] as? String ?? ""
            
            let batch = database.batch()

            let dareDocData = ["creator_profile_picture": profilePictureURL, "creator_uid": Auth.auth().currentUser!.uid, "creator_username": username, "dare_full_name": dareTitle]
            let dareDoc = database.collection("dares").document(trimmedTitle)
            let userDoc = database.collection("users").document(uid).collection("dares_created").document(trimmedTitle)
            
            batch.setData(dareDocData, forDocument: dareDoc)
            batch.setData(dareDocData, forDocument: userDoc)
            
            batch.commit { (error) in
                if error != nil {
                    return completion(error!)
                }
                return completion(nil)
            }
        }
    }
}
