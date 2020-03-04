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
    private static let currentUser = Auth.auth().currentUser!
    private static let uid = Auth.auth().currentUser!.uid
    
    // MARK: - Sign Up/Login
    
    static func handleEmailSignUp(email: String!, password: String!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, createError) in
            if createError != nil {
                return completion(createError)
            } else {
                guard let newUserID = result?.user.uid else { return completion(CustomError(message: "Failed creating user."))}
                FirebaseUtilities.createUsername(basedOn: email, appendedNumbersCount: 2) { (username, usernameError) in
                    if usernameError != nil {
                        return completion(usernameError)
                    }
                    let batch = database.batch()    // create user doc with basic user info, and add email/username to collection
                    
                    let userDoc = database.collection("users").document(newUserID)
                    batch.setData(["full_name": username!, "username": username!, "email": email ?? "", "uid": newUserID], forDocument: userDoc)
                    let usernameEmailDoc = database.collection("usernames").document(username!)
                    batch.setData(["email": email!], forDocument: usernameEmailDoc)
                    
                    batch.commit { (batchError) in
                        if batchError != nil {
                            return completion(batchError)
                        }
                        return completion(nil)
                    }
                }
            }
        }
    }
    
    static func handleFacebookAuthentication(viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        LoginManager().logIn(permissions: ["email", "public_profile"], from: viewController.self) { (result, permissionError) in
            if permissionError != nil {
                return completion(permissionError)
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
            Auth.auth().signIn(with: credential) { (res, signInError) in    // sign into Firebase with Facebook credential
                if signInError != nil {
                    return completion(signInError)
                }
                if let isNewUser = res?.additionalUserInfo?.isNewUser, isNewUser {
                    let graphRequestConnection = GraphRequestConnection()
                    let graphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, first_name, last_name"], tokenString: AccessToken.current?.tokenString, version: Settings.defaultGraphAPIVersion , httpMethod: .get)
                    graphRequestConnection.add(graphRequest) { (httpResponse, result, graphReqError) in     // request information from Facebook
                        if graphReqError != nil {
                            return completion(graphReqError)
                        }
                        if let result = result as? [String:Any] {
                            guard let newUserID = res?.user.uid else { return completion(CustomError(message: "Failed to create user."))}
                            let email = result["email"] as! String
                            let fullName = result["name"] as! String
                            
                            let usernameBasis = (result["name"] as! String).lowercased().replacingOccurrences(of: " ", with: "")
                            createUsername(basedOn: usernameBasis, appendedNumbersCount: 2) { (username, usernameError) in
                                if usernameError != nil {
                                    return completion(usernameError)
                                }
                                let batch = database.batch()    // create user doc with basic user info, and add email/username to collection
                                
                                let userDoc = database.collection("users").document(newUserID)
                                batch.setData(["username": username!, "email": email, "uid": newUserID, "full_name": fullName], forDocument: userDoc)
                                
                                let usernameEmailDoc = database.collection("usernames").document(username!)
                                batch.setData(["email": email], forDocument: usernameEmailDoc)
                                
                                batch.commit { (batchError) in
                                    if batchError != nil {
                                        return completion(batchError)
                                    }
                                    return completion(nil)
                                }
                            }
                        }
                    }
                    graphRequestConnection.start()
                } else {
                    return completion(nil)
                }
            }
        }
    }
    
    static func handleGoogleAuthentication(credential: AuthCredential!, user: GIDGoogleUser!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().signIn(with: credential) { (result, signInError) in
            if signInError != nil {
                return completion(signInError)
            }
            guard let newUserID = result?.user.uid else { return completion(CustomError(message: "Failed creating user.")) }
            if let isNewUser = result?.additionalUserInfo?.isNewUser, isNewUser {   // if the user is new, get info from google and send to database
                let fullName = user.profile.name
                let email = user.profile.email
                
                let usernameBasis = (user.profile.name!).replacingOccurrences(of: " ", with: "").lowercased()
                self.createUsername(basedOn: usernameBasis, appendedNumbersCount: 2) { (username, usernameError) in
                    if usernameError != nil {
                        return completion(usernameError)
                    }
                    let batch = database.batch()
                    
                    let userDoc = database.collection("users").document(newUserID)
                    batch.setData(["username": username!, "email": email!, "uid": newUserID, "full_name": fullName!], forDocument: userDoc)
                    
                    let usernameEmailDoc = database.collection("usernames").document(username!)
                    batch.setData(["email": email!], forDocument: usernameEmailDoc)
                    
                    batch.commit { (batchError) in
                        if batchError != nil {
                            return completion(batchError)
                        }
                        return completion(nil)
                    }
                }
            }
            return completion(nil)  // if user is not new, then completion
        }
    }
    
    static func handlePhoneAuthentication(credential: AuthCredential!, completion: @escaping(_ error: Error?) -> Void) {
        Auth.auth().signIn(with: credential) { (authDataResult, signInError) in
            if signInError != nil {
                return completion(signInError)
            }
            if authDataResult!.additionalUserInfo!.isNewUser {  // if new user, create basic user information and send to Firestore
                let uid = authDataResult!.user.uid
                self.createUsername(basedOn: "user", appendedNumbersCount: 2) { (username, usernameError) in
                    if usernameError != nil {
                        return completion(usernameError)
                    }
                    let data: [String: Any] = ["uid": uid, "username": username!, "full_name": username!] // TODO: add phone number to data
                    Firestore.firestore().collection("users").document(uid).setData(data)
                    return completion(nil)
                }
            } else {
                return completion(nil)
            }
        }
    }
    
    // creates a username, then checks to make sure that no other user has used that username
    static func createUsername(basedOn: String!, appendedNumbersCount: Int!, completion: @escaping(_ username: String?, _ error: Error?) -> Void) {
        let emailComponents = basedOn.components(separatedBy: "@")  // if string contains "@", takes the part of the string before the symbol
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
                
                createUsername(basedOn: username, appendedNumbersCount: (1)) { (username, error) in
                    completion(username, error)
                } // recursive, continues calling function until correct username, then returns in completion
            } else {
                return completion(username, nil)
            }
        }
    }
    
    // MARK: - Post Interaction
    
    static func likePost(postID: String!, creatoruid: String!, thumbnailPictureURL: String!, completion: @escaping(_ error: Error?) -> Void) {
        
        let batch = database.batch()    // increment the post's number of likes, add the likers uid to the post's list of likers, add the post to the liker's list of liked posts, add data to the post creator's activity
        
        let postStorageRef = database.collection("posts").document(postID)
        batch.updateData(["like_count": FieldValue.increment(Int64(1))], forDocument: postStorageRef)
        let postLikersDoc = postStorageRef.collection("post_likers").document(uid)
        batch.setData(["uid": uid], forDocument: postLikersDoc)
        let likedPostsDoc = database.collection("users").document(uid).collection("liked_posts").document(postID)
        batch.setData(["post_ID": postID!], forDocument: likedPostsDoc)
        
        database.collection("users").document(uid).getDocument { (snapshot, docError) in
            if docError != nil {
                return completion(docError)
            }
            guard let data = snapshot?.data() else { return completion(CustomError(message: "Error liking the post."))}
            let profilePictureURL = data["profile_image"] as? String ?? ""
            let username = data["username"] as? String ?? ""
            
            let docID = postID + "_" + uid
            let activityDoc = self.database.collection("users").document(creatoruid!).collection("activity").document(docID)
            let profileObject = ["profile_picture_URL": profilePictureURL, "uid": uid, "username": username]
            batch.setData(["profile": profileObject, "timestamp": Timestamp.init(), "type": "like", "thumbnail_picture_URL": thumbnailPictureURL!], forDocument: activityDoc)
            
            batch.commit { (batchError) in
                if batchError != nil {
                    return completion(batchError)
                }
                return completion(nil)
            }
        }
    }
    
    static func unlikePost(postID: String!, creatoruid: String!, completion: @escaping(_ error: Error?) -> Void) {
        
        let batch = database.batch()    // decrement the post's number of likes, remove the liker uid from the post's list of likers, remove the post from the liker's list of liked posts, remove the activity from the creator's profile
        
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
                return completion(error)
            }
            return completion(nil)
        }
    }
    
    // MARK: - Update User Data
    
    static func reauthenticatePasswordUser(email: String!, password: String!, completion: @escaping(_ error: Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        currentUser.reauthenticate(with: credential) { (result, error) in
            if error != nil {
                return completion(error)
            }
            return completion(nil)
        }
    }
    
    private static func reauthenticateFacebookUser(viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.authType = .reauthorize
        loginManager.logIn(permissions: [], from: viewController.self) { (result, logInError) in    // reauthentication only works if soon after login
            if logInError != nil {
                return completion(logInError)
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
            currentUser.reauthenticate(with: credential) { (result, reAuthError) in
                if reAuthError != nil {
                    return completion(reAuthError)
                }
                return completion(nil)
            }
        }
    }
    
    // TODO: Reauthenticate phone users
    static func reauthenticateUser(viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let providerID = currentUser.providerData[0].providerID     // reauthenticating with first provider type of (possible) list of providerIDs
        
        switch providerID {     // email has own function because email reauthentication needs password
        case "facebook.com":
            reauthenticateFacebookUser(viewController: viewController) { (error) in
                if error != nil {
                    return completion(error)
                }
                return completion(nil)
            }
        case "google.com":  // must make viewController a GIDSignInDelegate and do most work from there
            GIDSignIn.sharedInstance()?.signIn()
            return completion(nil)
        case "phone":
            break
        default:
            return completion(CustomError(message: "Cannot reauthenticate user."))
        }
    }
    
    static func updateUserProfileData(userProperty: String!, oldData: String!, newData: String!, completion: @escaping(_ error: Error?) -> Void) {
        let userDocRef = database.collection("users").document(uid)
        guard let newData = newData else { return completion(CustomError(message: "No new data to set."))}
        
        switch userProperty {
        case "Name":
            userDocRef.setData(["full_name": newData], merge: true)
        case "Username":
            let batch = database.batch()
            
            batch.updateData(["username": newData], forDocument: userDocRef)     // update username in user document
            
            let usernameEmailPath = database.collection("usernames").document(oldData)
            usernameEmailPath.getDocument { (usernameEmailDoc, usernameEmailError) in
                if usernameEmailError != nil {
                    return completion(usernameEmailError)
                }
                guard let data = usernameEmailDoc?.data() else { return }
                let email = data["email"] as? String ?? ""
                let newUsernameEmailPath = database.collection("usernames").document(newData)    // create new username/email doc
                batch.setData(["email": email], forDocument: newUsernameEmailPath)
                
                batch.deleteDocument(usernameEmailPath)    // delete old username in username-email
                
                userDocRef.collection("posts").getDocuments { (snapshot, postDocError) in     // change username on all the users posts
                    if postDocError != nil {
                        return completion(postDocError)
                    }
                    guard let unwrappedSnapshot = snapshot else { return completion(CustomError(message: "Error updating user data.")) }
                    let documents = unwrappedSnapshot.documents
                    
                    for document in documents {
                        let postID = document.documentID
                        let postPath = database.collection("posts").document(postID)
                        batch.updateData(["creator.username": newData], forDocument: postPath)
                    }
                    
                    batch.commit { (batchError) in
                        if batchError != nil {
                            return completion(batchError)
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
    
    static func updateUserEmail(newEmail: String, completion: @escaping(_ error: Error?) -> Void) {
        currentUser.updateEmail(to: newEmail) { (updateEmailerror) in   // update Authentication email
            if updateEmailerror != nil {
                return completion(updateEmailerror)
            }
            
            database.collection("users").document(uid).getDocument { (snapshot, docError) in
                if docError != nil {
                    return completion(docError)
                }
                guard let data = snapshot?.data() else { return completion(CustomError(message: "Error updating user email.")) }
                let username = data["username"] as! String
                
                let batch = database.batch()
                
                let userDoc = database.collection("users").document(uid)
                batch.updateData(["email": newEmail], forDocument: userDoc)
                let usernameEmailDoc = database.collection("usernames").document(username)
                batch.updateData(["email": newEmail], forDocument: usernameEmailDoc)
                
                batch.commit { (batchError) in
                    if batchError != nil {
                        return completion(batchError)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    // Link Login Methods
    
    static func linkEmailToAccount(currentUser: User, email: String, password: String, completion: @escaping(_ error: Error?) -> Void) {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        currentUser.link(with: credential) { (result, linkError) in     // link user current account with email account
            if linkError != nil {
                return completion(linkError)
            } else {
                updateUserEmail(newEmail: email) { (updateError) in     // slightly redundant because updating email directly after linking/setting it, but updating info correctly.
                    if updateError != nil {
                        return completion(updateError)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    static func linkFacebookToAccount(viewController: UIViewController, completion: @escaping(_ error: Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.authType = .reauthorize
        loginManager.logIn(permissions: [], from: viewController.self) { (result, logInError) in
            if logInError != nil {
                return completion(logInError)
            } else {
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)     // Link Facebook account with credential
                currentUser.link(with: credential) { (result, linkError) in
                    if linkError != nil {
                        return completion(linkError)
                    }
                    return completion(nil)
                }
            }
        }
    }
    
    // MARK: - User Interaction
    
    static func followUser(uidToFollow: String!, completion: @escaping(_ error: Error?) -> Void) {
                
        getUsername(userID: uid) { (username, usernameError) in
            if usernameError != nil {
                return completion(usernameError)
            } else {
                let batch = database.batch()

                // update relationship in relationships collection
                let relationshipDocPath = database.collection("relationships").document("\(uid)_\(uidToFollow!)")
                batch.setData(["follower_uid": uid, "following_uid": uidToFollow!, "follower_username": username!], forDocument: relationshipDocPath)
                
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
                getPostIDs(userID: uidToFollow, collection: "posts") { (postIDs, getPostsError) in
                    if getPostsError != nil {
                        return completion(getPostsError)
                    }
                    for postID in postIDs! {
                        let followingPostIDsPath = userDocPath.collection("following_post_IDs").document(postID)
                        batch.setData(["following_uid": uidToFollow!], forDocument: followingPostIDsPath)
                    }
                    
                    batch.commit { (batchError) in
                        if batchError != nil {
                            return completion(batchError)
                        }
                        return completion(nil)
                    }
                }
            }
        }
    }
    
    static func unfollowerUser(uidToUnfollow: String!, completion: @escaping(_ error: Error?) -> Void) {
        let batch = database.batch()
        
        // delete the relationship in the relationships collection
        let relationshipDocPath = database.collection("relationships").document("\(uid)_\(uidToUnfollow!)")
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
        getPostIDs(userID: uidToUnfollow, collection: "posts") { (postIDs, getPostsError) in
            if getPostsError != nil {
                return completion(getPostsError)
            }
            for postID in postIDs! {
                let followingPostIDsPath = userDocPath.collection("following_post_IDs").document(postID)
                batch.deleteDocument(followingPostIDsPath)
            }
            
            batch.commit { (batchError) in
                if batchError != nil {
                    return completion(batchError)
                }
            }
        }
    }
    
    static func getUsername(userID: String, completion: @escaping(_ username:String?, _ error: Error?) -> Void) {
        database.collection("users").document(userID).getDocument { (snapshot, error) in
            if error != nil {
                return completion(nil, error)
            }
            guard let documentData = snapshot?.data() else { return completion(nil, CustomError(message: "Failed to get user's username.")) }
            let username = documentData["username"] as? String ?? ""
            return completion(username, nil)
        }
    }
    
    // MARK: - Profile Navigation
    
    static func checkIfFollowing(followeruid: String!, followinguid: String?, completion: @escaping(_ isFollowing:Bool?, _ error: Error?) -> Void) {
        guard let followinguid = followinguid else { return completion(nil, CustomError(message: "Error fetching following status.")) }
        database.collection("relationships").document("\(followeruid!)_\(followinguid)").getDocument { (document, error) in
            if error != nil {
                return completion(nil, error)
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
    static func checkIfLiked(postID: String, completion: @escaping(_ isLiked:Bool?, _ error: Error?) -> Void) {
        database.collection("posts").document(postID).collection("post_likers").document(uid).getDocument { (document, error) in
            if error != nil {
                return completion(nil, error)
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
            guard let unwrappedSnapshot = snapshot else { return completion(nil, CustomError(message: "Error fetching posts."))}
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
                return completion(nil, error)
            }
            guard let unwrappedSnapshot = snapshot else { return completion(nil, CustomError(message: "Error fetching user posts."))}
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
                return completion(nil, error)
            }
            guard let unwrappedSnapshot = snapshot else { return completion(nil, CustomError(message: "Error fetching explore posts."))}
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
                    return completion(nil, error)
                }
                guard let unwrappedSnapshot = snapshot else { return completion(nil, CustomError(message: "Error fetching posts."))}
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
        database.collection("users").document(uid).getDocument { (snapshot, userDocError) in
            if userDocError != nil {
                return completion(userDocError)
            }
            guard let documentData = snapshot?.data() else { return completion(CustomError(message: "Error creating dare."))}
            let profilePictureURL = documentData["profile_image"] as? String ?? ""
            let username = documentData["username"] as? String ?? ""
            
            let batch = database.batch()

            let dareDocData = ["creator_profile_picture": profilePictureURL, "creator_uid": Auth.auth().currentUser!.uid, "creator_username": username, "dare_full_name": dareTitle]
            let dareDoc = database.collection("dares").document(trimmedTitle)
            let userDoc = database.collection("users").document(uid).collection("dares_created").document(trimmedTitle)
            
            batch.setData(dareDocData, forDocument: dareDoc)
            batch.setData(dareDocData, forDocument: userDoc)
            
            batch.commit { (batchError) in
                if batchError != nil {
                    return completion(batchError)
                }
                return completion(nil)
            }
        }
    }
}
