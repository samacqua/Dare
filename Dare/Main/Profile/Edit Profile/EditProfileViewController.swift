//
//  EditProfileViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/30/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

import GoogleSignIn

class EditProfileViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var googleReauthenticating = false
    var googleLinking = false
    
    var headerCell: ProfileHeaderNodeCell!
    
    var selectedImage: UIImage?
    var profileImage = UIButton()
    
    let profilePictureHeaderID = "headerProfilePictureCell"
    let sectionHeaderID = "sectionHeaderProfileCell"
    let reuseIdentifier = "editProfileCell"
        
    var headerTitles = [Constants.profileInfoTitle, Constants.privateInfoTitle, Constants.loginTypeTitle]
    var profileInfo: [(title: String, info: String)] = []
    var privateInfo: [(title: String, info: String)] = []
    var loginTypes: [String] = [Constants.emailPassword, Constants.facebook, Constants.google, Constants.phoneNumber]

    let database = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    
    // MARK: Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .lightGray
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(EditProfilePostCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(EditProfilePictureHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: profilePictureHeaderID)
        collectionView.register(EditProfileHeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeaderID)
        fetchUserData()
        self.title = "Edit Profile"
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    // MARK: Buttons and Actions
    
    @objc func profileImageTapped() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        present(pickerController, animated: true, completion: nil)
    }
    
    // MARK: Functions
    
    func fetchUserData() {
        database.collection("users").document(uid).getDocument { (document, error) in
            if error != nil {
                print("Error listening for new posts:", error!)
            }
            
            guard let unwrappedDocument = document else { return }
            
            if let image = Utilities.loadImageFromDiskWith(fileName: "\(self.uid).png") {
                self.profileImage.setImage(image, for: .normal)
                print("got saved image")
            } else {
                if unwrappedDocument.get("profile_image") != nil {
                    if let downloadURL = unwrappedDocument.get("profile_image") as? String {
                        let downloadURLRef = Storage.storage().reference(forURL: downloadURL)
                        downloadURLRef.getData(maxSize: 1 * 1024 * 1024) { (data, err) in
                            if err != nil {
                                print("Error downloading profile picture from database:", err!)
                            } else {
                                print("Data:", data!)
                                let image = UIImage(data: data!)
                                self.profileImage.setImage(image, for: .normal)
                            }
                        }
                    } else { print("Could not find URL to profile image") }
                } else { print("Could not find profile image") }
            }
            guard let documentData = unwrappedDocument.data() else { return }
            
            let name = documentData["full_name"] as? String ?? "Name"
            let username = documentData["username"] as? String ?? "Username"
            let bio = documentData["bio"] as? String ?? "Bio"
            let email = documentData["email"] as? String ?? "Email"
            let phone = documentData["phone_number"] as? String ?? "Phone number"
            
            self.profileInfo = [("Name", name), ("Username", username), ("Bio", bio)]
                        
            for provider in Auth.auth().currentUser!.providerData {
                let providerID = provider.providerID
                
                if providerID == Constants.passwordProviderID {
                    self.privateInfo.append(("Email", email))
                    self.privateInfo.append(("Password", "Change password"))
                    self.loginTypes.removeAll(where: { $0 == Constants.emailPassword })
                } else if providerID == Constants.facebookProviderID {
                    self.loginTypes.removeAll(where: { $0 == Constants.facebook })
                } else if providerID == Constants.googleProviderID {
                    self.loginTypes.removeAll(where: { $0 == Constants.google })
                } else if providerID == "Phone" {
                    self.privateInfo.append(("Phone number", phone))
                    self.loginTypes.removeAll(where: { $0 == Constants.phoneNumber })
                }
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func sendImageToDatabase() {
        
        let storageRef = Storage.storage().reference(forURL: "gs://dare-9adb9.appspot.com").child("profileimages").child(uid)
        
        // push data to database storage
        if let profileImg = selectedImage, let imageData = profileImg.jpegData(compressionQuality: 0.1) {
            Utilities.saveImage(imageName: "\(uid).png", image: profileImg)
            storageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("Error putting profile picture into storage: ", error!)
                    return
                }
                // include image in user info
                storageRef.downloadURL { (url, err) in
                    guard let profileImageURL = url else { return }
                    let userDocRef = self.database.collection("users").document(self.uid)
                    
                    let batch = self.database.batch()
                    batch.updateData(["profile_image": profileImageURL.absoluteString], forDocument: userDocRef)
                    
                    // update posts to have correct profile picture
                    userDocRef.collection("posts").getDocuments { (snapshot, error) in
                        if error != nil {
                            print("Error getting posts collection to update profile picture:", error!)
                        }
                        guard let unwrappedSnapshot = snapshot else { return }
                        let documents = unwrappedSnapshot.documents
                        
                        for document in documents {
                            let postID = document.documentID
                            let postPath = self.database.collection("posts").document(postID)
                            batch.updateData(["creator.profile_picture_URL": profileImageURL.absoluteString], forDocument: postPath)
                        }
                        batch.commit { (error) in
                            if error != nil {
                                print("Error updating profile image:", error!)
                            }
                        }
                    }
                }
            })
        }
    }
    
    // MARK: CollectionView
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section == 0 {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: profilePictureHeaderID, for: indexPath) as! EditProfilePictureHeaderCell
            profileImage = headerCell.profileImage
            headerCell.changeProfileImageButton.addTarget(self, action: #selector(profileImageTapped), for: .touchUpInside)
            headerCell.profileImage.addTarget(self, action: #selector(profileImageTapped), for: .touchUpInside)
            return headerCell
        }
        let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionHeaderID, for: indexPath) as! EditProfileHeaderCell
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            
            .foregroundColor : UIColor.black,
            .font : UIFont.boldSystemFont(ofSize: 18)
        ]
        print(indexPath.section - 1)
        print(headerTitles.count)
        let headerText = NSAttributedString(string: headerTitles[indexPath.section - 1], attributes: headerAttributes)
        sectionHeader.title.attributedText = headerText
        return sectionHeader
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EditProfilePostCell
        
        if headerTitles[indexPath.section - 1] == Constants.profileInfoTitle {
            cell.infoNameLabel.text = profileInfo[indexPath.row].0
            cell.userInfoLabel.text = profileInfo[indexPath.row].1
        } else if headerTitles[indexPath.section - 1] == Constants.privateInfoTitle {
            cell.infoNameLabel.text = privateInfo[indexPath.row].0
            cell.userInfoLabel.text = privateInfo[indexPath.row].1
        } else if headerTitles[indexPath.section - 1] == Constants.loginTypeTitle {
            cell.infoNameLabel.text = loginTypes[indexPath.row]
            cell.userInfoLabel.text = "Link account"
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? EditProfilePostCell else { return }
        if indexPath.section == 0 {
            return
        } else if headerTitles[indexPath.section - 1] == Constants.profileInfoTitle {
            let changeUserInfoVC = ChangeUserInfoViewController()
            changeUserInfoVC.userProperty = cell.infoNameLabel.text!
            changeUserInfoVC.userPropertyValue = cell.userInfoLabel.text!
            self.navigationController?.show(changeUserInfoVC, sender: self)
            
        } else if headerTitles[indexPath.section - 1] == Constants.privateInfoTitle {
            let reauthorizeVC = ReauthorizeEmailViewController()
            reauthorizeVC.userProperty = cell.infoNameLabel.text!
            reauthorizeVC.email = privateInfo[0].1
            self.navigationController?.show(reauthorizeVC, sender: self)
            
        } else if headerTitles[indexPath.section - 1] == Constants.loginTypeTitle {
            guard let currentUser = Auth.auth().currentUser else { return }
            if currentUser.providerData[0].providerID == Constants.passwordProviderID {
                let reauthorizeEmailVC = ReauthorizeEmailViewController()
                reauthorizeEmailVC.userProperty = cell.infoNameLabel.text!
                reauthorizeEmailVC.email = privateInfo[0].1
                reauthorizeEmailVC.linkingAccountType = cell.infoNameLabel.text!
                self.navigationController?.show(reauthorizeEmailVC, sender: self)
            } else {
                if currentUser.providerData[0].providerID == Constants.googleProviderID {
                    self.googleReauthenticating = true
                }
                FirebaseUtilities.reauthenticateUser(viewController: self) { (error) in
                    if error != nil {
                        self.view.showToast(message: error!.localizedDescription)
                        return
                    }
                    if currentUser.providerData[0].providerID == Constants.googleProviderID {
                        self.googleReauthenticating = false
                    }
                    let labelText = cell.infoNameLabel.text!
                    switch labelText {
                    case Constants.emailPassword:
                        let linkEmailVC = LinkEmailViewController()
                        self.navigationController?.show(linkEmailVC, sender: self)
                    case Constants.facebook:
                        FirebaseUtilities.linkFacebookToAccount(viewController: self) { (facebookError) in
                            if facebookError != nil {
                                self.view.showToast(message: facebookError!.localizedDescription)
                            }
                        }
                    case Constants.google:
                        self.googleLinking = true
                        GIDSignIn.sharedInstance()?.signIn()
                    case Constants.phoneNumber:
                        break
                    default:
                        break
                    }
                }
            }
        }
    }


func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    if section == 0 {
        let cellWidth = self.view.bounds.width
            let cellHeight: CGFloat = 160.0
            return CGSize(width: cellWidth, height: cellHeight)
        }
        let cellWidth = self.view.bounds.width
        let cellHeight: CGFloat = 45.0
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sectionCount = headerTitles.count
        print("section count:", sectionCount)
        return sectionCount + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }

        if headerTitles[section - 1] == Constants.profileInfoTitle {
            print("profile items:", profileInfo.count)
            return profileInfo.count
        } else if headerTitles[section - 1] == Constants.privateInfoTitle {
            print("private items:", privateInfo.count)
            return privateInfo.count
        } else if headerTitles[section - 1] == Constants.loginTypeTitle {
            print("link items:", loginTypes.count)
            return loginTypes.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width
        let cellHeight: CGFloat = 45.0
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}

// MARK: Profile Picker Extension

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImage = image
            profileImage.setImage(image, for: .normal)
            sendImageToDatabase()
        }
        dismiss(animated: true, completion: nil)
    }
}

extension EditProfileViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            self.view.showToast(message: error!.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        if googleReauthenticating {
            Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                    return
                }
                print("success")
            })
        }
        if googleLinking {
            Auth.auth().currentUser?.link(with: credential, completion: { (result, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                } else {
                    self.googleLinking = false
                }
            })
        }
    }
}
