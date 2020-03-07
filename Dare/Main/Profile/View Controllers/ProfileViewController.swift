//
//  ProfileViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseAuth

class ProfileViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var collectionNode: ASCollectionNode!
    
    var onCompleted = true
    
    var profile = Profile()
    var userPosts = [PostPreview]()
    var userDares = [Dare]()
    
    var selectedImage: UIImage?
    
    let uid = Auth.auth().currentUser!.uid
            
    // MARK: - Initialization and Setup

    init() {
        let flowLayout = UICollectionViewFlowLayout()
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)

        super.init(node: collectionNode)
        
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionNode.delegate = self
        collectionNode.dataSource = self
        
        setUpElements()
        
        let userInfoFields = ["full_name", "username", "dare_count", "following_count", "follower_count", "profile_image", "bio"]
        FirebaseUtilities.getUserInfo(userID: uid, fields: userInfoFields) { (userInfo, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            self.profile.fullName = userInfo!["full_name"] as? String ?? ""
            self.profile.username = userInfo!["username"] as? String ?? ""
            self.profile.daresCompleted = userInfo!["dare_count"] as? Int ?? 0
            self.profile.followingCount = userInfo!["following_count"] as? Int ?? 0
            self.profile.followerCount = userInfo!["follower_count"] as? Int ?? 0
            self.profile.pathToProfileImage = userInfo!["profile_image"] as? String ?? ""
            self.profile.bio = userInfo!["bio"] as? String ?? ""
            
            self.title = self.profile.username
            self.tabBarItem.title = nil
            
            DispatchQueue.main.async {
                self.collectionNode.reloadData()
            }
        }
        
        FirebaseUtilities.getUserPostPreviews(profileuid: uid) { (postPreviews, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            guard let postPreviews = postPreviews else { return }
            self.userPosts = postPreviews
            self.collectionNode.reloadData()
        }
        FirebaseUtilities.fetchProfileImage { (image, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            self.selectedImage = image!
            self.collectionNode.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionNode.reloadSections(IndexSet(integersIn: 0...0))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(appSettingsTapped))
    }
    
    func setUpElements() {
        collectionNode.view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        collectionNode.allowsSelection = true
        collectionNode.alwaysBounceVertical = true
        self.view.addSubnode(collectionNode)
    }
    
    // MARK: - Actions
    
    @objc func appSettingsTapped() {
        let layout = UICollectionViewFlowLayout()
        self.navigationController?.show(ProfileSettingsViewController(collectionViewLayout: layout), sender: self)
    }
    
    @objc func profileImageTouchUpInside() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        present(pickerController, animated: true, completion: nil)
    }
    
    @objc func editProfileTouchUpInside() {
        let layout = UICollectionViewFlowLayout()
        let editProfileVC = EditProfileViewController(collectionViewLayout: layout)
        self.navigationController?.show(editProfileVC, sender: self)
    }
    
    @objc func followingTouchUpInside() {
        let followsVC = FollowsViewController()
        followsVC.followersOrFollowing = "Following"
        followsVC.userID = uid
        self.navigationController?.show(followsVC, sender: self)
    }
    
    @objc func followersTouchUpInside() {
        let followsVC = FollowsViewController()
        followsVC.followersOrFollowing = "Followers"
        followsVC.userID = uid
        self.navigationController?.show(followsVC, sender: self)
    }
    
    @objc func likedPostsTouchUpInside() {
        self.view.showToast(message: "Liked posts pressed")
    }
    
    @objc func segmentedControlSwitched(_ segmentedControl: UISegmentedControl) {
        let indexSet = IndexSet(integersIn: 1...1)
        if segmentedControl.selectedSegmentIndex == 0 {
            onCompleted = true
            collectionNode.reloadSections(indexSet)
        } else {
            onCompleted = false
            FirebaseUtilities.fetchUserDares { (dares, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
                self.userDares = dares!
                self.collectionNode.reloadSections(IndexSet(integersIn: 1...1))
            }
        }
    }
    
    // MARK: CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        if indexPath.section == 0 {
            let headerCell = ProfileHeaderNodeCell()
            
            headerCell.parentVC = self
            
            headerCell.profileImage.image = selectedImage
            let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTouchUpInside))
            headerCell.profileImage.view.addGestureRecognizer(tap)
            headerCell.profileImage.view.isUserInteractionEnabled = true
            
            let nameAttributes = Utilities.createAttributes(color: .black, font: .boldSystemFont(ofSize: 26), shadow: false)
            let bioAttributes = Utilities.createAttributes(color: .black, font: .systemFont(ofSize: 14), shadow: false)
            let followCount = Utilities.createAttributes(color: .black, font: .boldSystemFont(ofSize: 14), shadow: false)
            let followLabel = Utilities.createAttributes(color: .black, font: .systemFont(ofSize: 14), shadow: false)
            let dareCountAttributes = Utilities.createAttributes(color: .lightGray, font: .systemFont(ofSize: 14), shadow: false)
            
            headerCell.nameLabel.attributedText = NSAttributedString(string: self.profile.fullName ?? "", attributes: nameAttributes)
            
            let bioText = (self.profile.bio ?? "").replacingOccurrences(of: "\n", with: "\n").replacingOccurrences(of: "\\n", with: "\n")
            headerCell.bioLabel.attributedText = NSAttributedString(string: bioText, attributes:
                bioAttributes)
            
            let followerButtonString = NSMutableAttributedString(string: String((self.profile.followerCount ?? 0)), attributes: followCount)
            let followersString = NSMutableAttributedString(string: " followers", attributes: followLabel)
            followerButtonString.append(followersString)
            
            headerCell.followerButton.addTarget(self, action: #selector(followersTouchUpInside), forControlEvents: .touchUpInside)
            headerCell.followerButton.setAttributedTitle(followerButtonString, for: .normal)
            
            let followingButtonString = NSMutableAttributedString(string: String((self.profile.followingCount ?? 0)), attributes: followCount)
            let followingString = NSMutableAttributedString(string: " following", attributes: followLabel)
            followingButtonString.append(followingString)
            
            headerCell.followingButton.addTarget(self, action: #selector(followingTouchUpInside), forControlEvents: .touchUpInside)
            headerCell.followingButton.setAttributedTitle(followingButtonString, for: .normal)
            
            headerCell.dareCountLabel.attributedText = NSAttributedString(string: "Dares completed: \(String(self.profile.daresCompleted ?? 0))", attributes: dareCountAttributes)
            
            
            headerCell.editProfileButton.addTarget(self, action: #selector(editProfileTouchUpInside), forControlEvents: .touchUpInside)
            
            headerCell.segmentedView.addTarget(self, action: #selector(self.segmentedControlSwitched(_:)), for: .valueChanged)
            headerCell.likedPostsButton.addTarget(self, action: #selector(likedPostsTouchUpInside), forControlEvents: .touchUpInside)

            return headerCell
        } else if indexPath.section == 1  && onCompleted {
            let cellNode = ProfileCellNode()
            
            let thumbnailImageURL = userPosts[indexPath.row].thumbnailImageURL
            cellNode.thumbnailImage.url = URL(string: thumbnailImageURL)
            
            return cellNode
        } else {
            let cellNode = CategoryTableCellNode()
            cellNode.mainLabel.attributedText = NSAttributedString(string: userDares[indexPath.row].dareNameFull)
            cellNode.secondaryLabel.attributedText = NSAttributedString(string: (String(userDares[indexPath.row].numberOfAttempts) + " attempts"))
            cellNode.profileImageView.url = URL(string: userDares[indexPath.row].creatorProfilePicturePath)
            return cellNode
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        let screenWidth = self.view.bounds.width
        let screenHeight = self.view.bounds.height
        
        if indexPath.section == 0 {
            let minSize = CGSize(width: screenWidth, height: 50)
            let maxSize = CGSize(width: screenWidth, height: screenHeight)
            return(ASSizeRange(min: minSize, max: maxSize))
        } else if indexPath.section == 1  && onCompleted {
            let cellWidth = screenWidth / 3 - 1
            let minSize = CGSize(width: cellWidth, height: cellWidth * 1.5)
            let maxSize = CGSize(width: cellWidth, height: cellWidth * 1.5)
            return(ASSizeRange(min: minSize, max: maxSize))
        } else {
            let cellWidth = screenWidth
            let minSize = CGSize(width: cellWidth, height: 50)
            let maxSize = CGSize(width: cellWidth, height: 100)
            return(ASSizeRange(min: minSize, max: maxSize))
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        } else if indexPath.section == 1  && onCompleted {
            let postSelectedVC = ProfilePostSelectedViewController()
            var postIDs = [""]
            for post in userPosts {
                postIDs.append(post.postID)
            }
            postSelectedVC.postIDs = postIDs
            postSelectedVC.postIndexPathRow = indexPath.row
            navigationController?.show(postSelectedVC, sender: self)
        } else if indexPath.section == 1  && !onCompleted {
            let cellID = userDares[indexPath.row].dareNameID
            self.view.showToast(message: cellID!)
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            if onCompleted {
                return userPosts.count
            } else {
                return userDares.count
            }
        }
    }
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 2
    }
}

// MARK: Image Picker Extension

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            selectedImage = image
            self.collectionNode.reloadData()
            FirebaseUtilities.sendImageToDatabase(selectedImage: selectedImage) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
}
