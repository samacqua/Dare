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
import FirebaseStorage

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
    
    static func handlePhoneAuthentication(verificationCode: String, verificationID: String, completion: @escaping(_ error: Error?) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
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
            batch.setData(["profile": profileObject, "timestamp": FieldValue.serverTimestamp(), "type": "like", "thumbnail_picture_URL": thumbnailPictureURL!, "post_ID": postID!], forDocument: activityDoc)
            
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
            return completion(CustomError(message: "User property not recognized."))
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
        
        getUserInfo(userID: uidToFollow, fields: ["username"]) { (userInfo, userInfoError) in
            let username = userInfo!["username"] as! String
            if userInfoError != nil {
                return completion(userInfoError)
            } else {
                let batch = database.batch()    // activity update done over cloud function
                
                // update relationship in relationships collection
                let relationshipDocPath = database.collection("relationships").document("\(uid)_\(uidToFollow!)")
                batch.setData(["follower_uid": uid, "following_uid": uidToFollow!, "follower_username": username], forDocument: relationshipDocPath)
                
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
        
        // delete the activity document in the unfollowed users data
        let activityDocPath = followingUserDocPath.collection("activity").document("\(uid)_\(uidToUnfollow!)")
        batch.deleteDocument(activityDocPath)
        
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
    
    static func getUserInfo(userID: String, fields: [String], completion: @escaping(_ userInfo: [String: Any]?, _ error: Error?) -> Void) {
        database.collection("users").document(userID).getDocument { (snapshot, error) in
            if error != nil {
                return completion(nil, error)
            }
            guard let documentData = snapshot?.data() else { return completion(nil, CustomError(message: "Failed to get user info.")) }
            var userInfoDict = [String: Any]()
            
            for field in fields {
                let userInfoValue = documentData[field]
                userInfoDict[field] = userInfoValue
            }
            return completion(userInfoDict, nil)
        }
    }
    
    // MARK: - Profile
    
    static func sendImageToDatabase(selectedImage: UIImage?, completion: @escaping(_ error: Error?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: "gs://dare-9adb9.appspot.com").child("profileimages").child(uid)
        
        // push data to database storage
        if let profileImg = selectedImage, let imageData = profileImg.jpegData(compressionQuality: 0.1) {
            Utilities.saveImage(imageName: "\(uid).png", image: profileImg, completion: { (saveImageError) in
                if saveImageError != nil {
                    return completion(saveImageError)
                }
            })
                
            storageRef.putData(imageData, metadata: nil, completion: { (metadata, putDataError) in
                if putDataError != nil {
                    return completion(putDataError)
                }
                // include image in user info
                storageRef.downloadURL { (url, downloadError) in
                    if downloadError != nil {
                        return completion(downloadError)
                    }
                    guard let profileImageURL = url else { return }
                    let userDocRef = self.database.collection("users").document(self.uid)
                    
                    let batch = self.database.batch()
                    batch.updateData(["profile_image": profileImageURL.absoluteString], forDocument: userDocRef)
                    
                    // update posts to have correct profile picture
                    userDocRef.collection("posts").getDocuments { (snapshot, getuserPostsError) in
                        if getuserPostsError != nil {
                            return completion(getuserPostsError)
                        }
                        guard let unwrappedSnapshot = snapshot else { return }
                        let documents = unwrappedSnapshot.documents
                        
                        for document in documents {
                            let postID = document.documentID
                            let postPath = self.database.collection("posts").document(postID)
                            batch.updateData(["creator.profile_picture_URL": profileImageURL.absoluteString], forDocument: postPath)
                        }
                        batch.commit { (batchError) in
                            if batchError != nil {
                                return completion(batchError)
                            }
                            return completion(nil)
                        }
                    }
                }
            })
        }
    }
    
    static func fetchProfileImage(completion: @escaping(_ image: UIImage?, _ error: Error?) -> Void) {
        if let image = Utilities.loadImageFromDiskWith(fileName: "\(self.uid).png") {
            return completion(image, nil)
        } else {
            let downloadURLPath = self.database.collection("users").document(uid)
            downloadURLPath.getDocument { (document, downloadURLError) in
                if downloadURLError != nil {
                    return completion(nil, downloadURLError)
                }
                if let document = document, document.exists {
                    if document.get("profile_image") != nil {
                        if let downloadURL = document.get("profile_image") as? String {
                            let downloadURLRef = Storage.storage().reference(forURL: downloadURL)
                            downloadURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, getDataError) in
                                if getDataError != nil {
                                    return completion(nil, getDataError)
                                } else {
                                    let image = UIImage(data: data!)
                                    Utilities.saveImage(imageName: "\(self.uid).png", image: image!) { (saveImageError) in
                                        if saveImageError != nil {
                                            return completion(nil, saveImageError)
                                        }
                                    }
                                    return completion(image, nil)
                                }
                            }
                        } else { return completion(nil, CustomError(message: "Could not find URL to profile image")) }
                    } else { return completion(nil, CustomError(message: "Could not find profile image")) }
                }
            }
        }
    }
    
    static func fetchUserDares(completion: @escaping(_ dares: [Dare]?, _ error: Error?) -> Void) {
        let dareCollectionRef = database.collection("users").document(uid).collection("dares_created")
        dareCollectionRef.getDocuments { (snapshot, error) in
            if error != nil {
                return completion(nil, error)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            var dares = [Dare]()
            for document in documents {
                let documentData = document.data()
                
                
                let dareNameFull = documentData["dare_full_name"] as? String ?? ""
                let dareID = document.documentID
                let numberOfAttempts = documentData["number_of_attempts"] as? Int ?? 0
                let profilePictureURL = documentData["creator_profile_picture"] as? String ?? ""
                
                let dare = Dare()
                dare.dareNameFull = dareNameFull
                dare.dareNameID = dareID
                dare.numberOfAttempts = numberOfAttempts
                dare.creatorProfilePicturePath = profilePictureURL
                dares.append(dare)
            }
            return completion(dares, nil)
        }
    }
    
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
            print(postIDs.count)
            var trimmedPostIDs = postIDs
            if postIDs.count > 10 {
                trimmedPostIDs = Array(postIDs.prefix(10))
            }
            let postsRef = self.database.collection("posts").whereField("post_ID", in: trimmedPostIDs)
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
    
    // MARK: - Dare Generation
    
    static func createDare(dareTitle: String, completion: @escaping(_ error: Error?) -> Void) {
        if !Utilities.isDareAllowed(dareTitle) {
            return completion(CustomError(message: "The title of your Dare does not conform to our community guidelines."))
        }
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
    
    static func fetchDaresInCategory(category: String, completion: @escaping(_ dares: [Dare]?, _ error: Error?) -> Void) {        database.collection("universal_dare_categories").document(category.lowercased()).getDocument { (document, getCategoryDocError) in
            if getCategoryDocError != nil {
                return completion(nil, getCategoryDocError)
            }
            guard let data = document?.data() else { return completion(nil, CustomError(message: "Error fetching \(category) dares."))}
        
        var dares = [Dare]()
        var daresIteratedCount = 0
        
            for (_, name) in data {
                daresIteratedCount += 1
                let stringName = name as! String
                let dare = Dare()
                dare.dareNameID = stringName
                self.database.collection("dares").document(stringName).getDocument { (dareDocument, getDareDocError) in
                    if getDareDocError != nil {
                        return completion(nil, getDareDocError)
                    }
                    
                    guard let dareData = dareDocument?.data() else { return }
                    
                    dare.creatorProfilePicturePath = dareData["creator_profile_picture"] as? String ?? ""
                    dare.numberOfAttempts = dareData["number_of_attempts"] as? Int ?? 0
                    dare.dareNameFull = dareData["dare_full_name"] as? String ?? "Dare"
                    
                    dares.append(dare)
                    
                    if daresIteratedCount >= data.count {
                        return completion(dares, nil)
                    }
                }
            }
        }
    }
    
    static func fetchDare(dareID: String, completion: @escaping(_ dare: Dare?, _ error: Error?) -> Void) {
        database.collection("dares").document(dareID).getDocument { (snapshot, error) in
            if error != nil {
                return completion(nil, error)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            guard let data = unwrappedSnapshot.data() else { return }
            let dare = Dare()
            dare.dareNameFull = data["dare_full_name"] as? String
            dare.creatorduid = data["creator_uid"] as? String
            dare.creatorUsername = data["creator_username"] as? String
            dare.numberOfAttempts = data["number_of_attempts"] as? Int
            dare.creatorProfilePicturePath = data["creator_profile_picture"] as? String
            
            return completion(dare, nil)
        }
    }
    
    // MARK: - Activity
    
    static func fetchRecentActivity(completion: @escaping(_ activityInstances: [Activity]?, _ error: Error?) -> Void) {
        
        let activityRef = database.collection("users").document(uid).collection("activity")
        var queryRef: Query
        
        queryRef = activityRef.order(by: "timestamp", descending: true).limit(to: 10)   // get the 10 most recent activities
        queryRef.getDocuments { (snapshot, queryError) in
            if queryError != nil {
                return completion(nil, queryError)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var activitiesCheckedCount = 0  // since it is necessary to do an asynchronous function within the for loop, the for loop may complete before the asynchronous function is complete. So, there has to be a check to ensure async functions completed.
            var activities = [Activity]()
            
            for document in documents {
                let documentData = document.data()
                
                let postID = documentData["post_ID"] as? String ?? ""
                let timestamp = documentData["timestamp"] as! Timestamp? ?? Timestamp(date: Date(timeIntervalSince1970: 0))
                let timestampDate = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
                
                let profileData = documentData["profile"] as? [String: Any] ?? ["":""]
                let profilePictureURL = profileData["profile_picture_URL"] as? String ?? ""
                let notificationuid = profileData["uid"] as? String ?? ""
                let username = profileData["username"] as? String ?? ""
                
                let type = documentData["type"] as? String ?? ""
                
                let activity = Activity(uid: notificationuid, profilePictureURL: profilePictureURL, username: username, type: type, timestamp: timestampDate)
                
                if type == "like" || type == "comment" {
                    let thumbnailPictureURL = documentData["thumbnail_picture_URL"] as? String ?? ""
                    activity.thumbnailPictureURL = thumbnailPictureURL
                    activity.postID = postID
                    
                    activities.append(activity)
                    activitiesCheckedCount += 1
                } else if type == "follow" {
                    FirebaseUtilities.checkIfFollowing(followeruid: self.uid, followinguid: notificationuid) { (isFollowing, followingError) in
                        if followingError != nil {
                            return completion(nil, followingError)
                        }
                        activity.isCurrentUserFollowing = isFollowing!
                        activities.append(activity)
                        activitiesCheckedCount += 1
                        
                        if activitiesCheckedCount >= documents.count {  // @ the end of each for loop, adds 1 to activitiesCheckedCount. if this number is >= number of documents, completed query and can return
                            activities.sort(by: {$0.timestamp.timeIntervalSinceReferenceDate > $1.timestamp.timeIntervalSinceReferenceDate})    // since async functions may finish after for loop completed, despite query being reversed timestamp, the returned array may be out of order. So, sorting it.
                            return completion(activities, nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Comments
    
    static func fetchComments(postID: String, lastComment: Comment?, completion: @escaping(_ comments:[Comment]?, _ error: Error?) -> ()) {
        
        let commentsRef = database.collection("posts").document(postID).collection("comments").order(by: "number_of_likes", descending: true)
        var queryRef: Query
        
        if lastComment == nil {
            queryRef = commentsRef.limit(to: 8)
        } else {
            let lastNumberOfLikes = lastComment!.numberOfLikes
            queryRef = commentsRef.start(after: [lastNumberOfLikes]).limit(to: 8)
        }
        
        queryRef.getDocuments { (snapshot, error) in
            if error != nil {
                return completion(nil, error)
            }
            
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var tempComments = [Comment]()
            
            for document in documents {
                
                let documentData = document.data()
                
                let commenterData = documentData["commenter"] as? [String: Any] ?? ["": ""]
                
                let commenteruid = commenterData["uid"] as? String ?? ""
                let commenterProfilePictureURL = commenterData["profile_picture_URL"] as? String ?? ""
                let commenterUsername = commenterData["username"] as? String ?? ""

                let numberOfLikes = documentData["number_of_likes"] as? Int ?? 0
                let commentText = documentData["comment_text"] as? String ?? ""
                
                let commentID = documentData["comment_ID"] as? String ?? ""
                
                if commentID != lastComment?.commentID {
                    let comment = Comment(uid: commenteruid, profilePictureURL: commenterProfilePictureURL, username: commenterUsername, comment: commentText, numberOfLikes: numberOfLikes, commentID: commentID)
                    tempComments.append(comment)
                }
            }
            return completion(tempComments, nil)
        }
    }
    
    static func sendCommentToDatabase(commentText: String, postID: String, completion: @escaping(_ error: Error?) -> Void) {
        let batch = database.batch()
        
        FirebaseUtilities.getUserInfo(userID: uid, fields: ["profile_image", "username"]) { (userInfo, error) in
            if error != nil {
                return completion(error)
            }
            let username = userInfo!["username"] as! String
            let profilePictureURL = userInfo!["profile_image"] as! String
            
            let postPath = self.database.collection("posts").document(postID)
            batch.updateData(["number_of_comments": FieldValue.increment(Int64(1))], forDocument: postPath)
            
            let commentPath = postPath.collection("comments").document()
            let commenter = ["profile_picture_URL": profilePictureURL, "uid": self.uid, "username": username]
            let commentData: [String: Any] = ["comment_ID": commentPath.documentID, "comment_text": commentText, "commenter": commenter, "number_of_likes": Int(0)]
            batch.setData(commentData, forDocument: commentPath)
            
            batch.commit { (commitError) in
                if commitError != nil {
                    return completion(commitError)
                }
                return completion(nil)
            }
        }
    }
    
    // MARK: - Follows
    
    static func fetchFollows(userID: String, followersOrFollowing: String, completion: @escaping(_ profilePreviews: [ProfilePreview]?, _ error: Error?) -> Void ) {
        if followersOrFollowing == "Followers" {
            database.collection("relationships").whereField("following_uid", isEqualTo: userID).getDocuments { (snapshot, getRelationshipError) in
                if getRelationshipError != nil {
                    return completion(nil, getRelationshipError)
                }
                guard let unwrappedSnapshot = snapshot else { return }
                let documents = unwrappedSnapshot.documents
                
                var profilePreviews = [ProfilePreview]()
                var activitiesCheckedCount = 0  // since it is necessary to do an asynchronous function within the for loop, the for loop may complete before the asynchronous function is complete. So, there has to be a check to ensure async functions completed.
                
                for document in documents {
                    let documentData = document.data()
                    
                    let followeruid = documentData["follower_uid"] as? String ?? ""
                    
                    self.database.collection("users").document(followeruid).getDocument { (userSnapshot, userError) in
                        if userError != nil {
                            return completion(nil, userError)
                        }
                        guard let unwrappedUserSnapshot = userSnapshot else { return }
                        let data = unwrappedUserSnapshot.data()
                        
                        let username = data!["username"] as? String ?? ""
                        let profilePictureURL = data!["profile_image"] as? String ?? ""
                        let fullName = data!["full_name"] as? String ?? ""
                        
                        self.checkIfFollowing(followeruid: uid, followinguid: followeruid) { (isFollowing, followingError)  in
                            if followingError != nil {
                                return completion(nil, followingError)
                            }
                            let profilePreview = ProfilePreview(uid: followeruid, fullName: fullName, username: username, profileImageURL: profilePictureURL, isFollowing: isFollowing!)
                            if followeruid == self.uid {
                                profilePreview.isCurrentUser = true
                            }
                            profilePreviews.append(profilePreview)
                            activitiesCheckedCount += 1
                            
                            if activitiesCheckedCount >= documents.count {
                                return completion(profilePreviews, nil)
                            }
                        }
                    }
                }
            }
        } else if followersOrFollowing == "Following" {
            database.collection("relationships").whereField("follower_uid", isEqualTo: userID).getDocuments { (snapshot, getRelationshipError) in
                if getRelationshipError != nil {
                    return completion(nil, getRelationshipError)
                }
                guard let unwrappedSnapshot = snapshot else { return }
                let documents = unwrappedSnapshot.documents
                
                var profilePreviews = [ProfilePreview]()
                var activitiesCheckedCount = 0  // since it is necessary to do an asynchronous function within the for loop, the for loop may complete before the asynchronous function is complete. So, there has to be a check to ensure async functions completed.
                
                for document in documents {
                    let documentData = document.data()
                    
                    let followinguid = documentData["following_uid"] as? String ?? ""
                    
                    self.database.collection("users").document(followinguid).getDocument { (userSnapshot, userError) in
                        if userError != nil {
                            return completion(nil, userError)
                        }
                        guard let unwrappedUserSnapshot = userSnapshot else { return }
                        let data = unwrappedUserSnapshot.data()
                        
                        let username = data!["username"] as? String ?? ""
                        let profilePictureURL = data!["profile_image"] as? String ?? ""
                        let fullName = data!["full_name"] as? String ?? ""
                        
                        self.checkIfFollowing(followeruid: uid, followinguid: followinguid) { (isFollowing, followingError) in
                            if followingError != nil {
                                return completion(nil, followingError)
                            }
                            let profilePreview = ProfilePreview(uid: followinguid, fullName: fullName, username: username, profileImageURL: profilePictureURL, isFollowing: isFollowing!)
                            if followinguid == uid {
                                profilePreview.isCurrentUser = true
                            }
                            profilePreviews.append(profilePreview)
                            activitiesCheckedCount += 1
                            
                            if activitiesCheckedCount >= documents.count {
                                return completion(profilePreviews, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Post Creation
    
    static func sendPostToFirestore(videoURL: URL, caption: String, dare: Dare, postPath: DocumentReference, completion: @escaping(_ uploadTask: StorageUploadTask?, _ error: Error?) -> Void) {
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        let filename = NSUUID().uuidString
        let vidFilename = filename  + ".mov"
        
        if let videoData = NSData(contentsOf: videoURL) as Data? {
            let storageRef = Storage.storage().reference()
            let vidRef = storageRef.child("post_videos/\(vidFilename)")
            
            let uploadTask = vidRef.putData(videoData, metadata: nil) { (metadata, putDataError) in
                if putDataError != nil {
                    return completion(nil, putDataError)
                }
                
                vidRef.downloadURL { (url, downloadError) in
                    if downloadError != nil {
                        return completion(nil, downloadError)
                    }
                    self.database.collection("users").document(self.uid).getDocument { (document, getDocError) in
                        if getDocError != nil {
                            return completion(nil, getDocError)
                        }
                        let postID = postPath.documentID
                        let dareNameFull = dare.dareNameFull ?? ""
                        let dareID = dare.dareNameID ?? ""
                        
                        let username = document?.get("username") as! String
                        let profilePictureURL = document?.get("profile_image") as! String
                        
                        let creatorObject = ["uid": self.uid, "username": username, "profile_picture_URL": profilePictureURL]
                        
                        let postData: [String: Any] = ["video_URL": url!.absoluteString, "dare_full_name": dareNameFull, "dare_ID": dareID, "caption": caption, "post_ID": postID, "creator": creatorObject, "timestamp": Timestamp.init()]
                        
                        postPath.setData(postData , mergeFields: Array(postData.keys))
                        let userPath = self.database.collection("users").document(self.uid)
                        userPath.collection("posts").document(postID).setData(["post_ID": postID], mergeFields: ["post_ID"])
                        userPath.collection("following_post_IDs").document(postID).setData(["post_ID": postID], mergeFields: ["post_ID"])
                        
                        self.sendThumbnailToDatabase(filename: filename, postPath: postPath, videoURL: videoURL) { (thumbnailError) in
                            if thumbnailError != nil {
                                return completion(nil, thumbnailError)
                            }
                        }
                    }
                }
            }
            return completion(uploadTask, nil)
        }
    }
    
    static func sendThumbnailToDatabase(filename: String, postPath: DocumentReference, videoURL: URL, completion: @escaping(_ error: Error?) -> Void ) {
        
        let postID = postPath.documentID
        let imageFilename = filename  + ".JPEG"
        let storageRef = Storage.storage().reference(forURL: Constants.dareStorageURL).child("post_thumbnails").child(imageFilename)
        
        let thumbnail = Utilities.createThumbnail(url: videoURL)
        
        // push data to database storage
        guard let imageData = thumbnail!.jpegData(compressionQuality: 0.1) else { return completion(CustomError(message: "Error creating post thumbnail."))}
        storageRef.putData(imageData, metadata: nil) { (metadata, putDataError) in
            if putDataError != nil {
                return completion(putDataError)
            }
            storageRef.downloadURL { (url, downloadError) in
                if downloadError != nil {
                    return completion(downloadError)
                }
                guard let thumbnailURL = url else { return }
                postPath.setData(["thumbnail_image": thumbnailURL.absoluteString], mergeFields: ["thumbnail_image"])
                self.database.collection("users").document(self.uid).collection("posts").document(postID).setData(["thumbnail_image": thumbnailURL.absoluteString], mergeFields: ["thumbnail_image"])
            }
        }
    }
}
