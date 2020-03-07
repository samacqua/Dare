//
//  ExploreProfileViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/28/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseAuth

class ExploreProfileViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var collectionNode: ASCollectionNode!
    var creatoruid: String!
        
    var onCompleted = true
    var isFollowing: Bool = false
    
    var profile = Profile()
    var userPosts = [PostPreview]()
    var userDares = [Dare]()
    
    let uid = Auth.auth().currentUser!.uid
    
    var needsToLoad: Bool = true
        
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
        collectionNode.view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        collectionNode.allowsSelection = true
        collectionNode.alwaysBounceVertical = true
        self.view.addSubnode(collectionNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let userInfoFields = ["full_name", "username", "dare_count", "following_count", "follower_count", "profile_image", "bio"]
        if needsToLoad {
            FirebaseUtilities.getUserInfo(userID: creatoruid, fields: userInfoFields) { (userInfo, error) in
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
            FirebaseUtilities.getUserPostPreviews(profileuid: creatoruid) { (postPreviews, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
                self.userPosts = postPreviews!
                self.collectionNode.reloadData()
            }
            FirebaseUtilities.checkIfFollowing(followeruid: uid, followinguid: creatoruid) { (isFollowing, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
                self.isFollowing = isFollowing!
            }
            needsToLoad = false
        }
    }
    
    // MARK: - Actions
    
    @objc func followingTouchUpInside() {
        let followsVC = FollowsViewController()
        followsVC.followersOrFollowing = "Following"
        followsVC.userID = creatoruid
        self.navigationController?.show(followsVC, sender: self)
    }
    
    @objc func followersTouchUpInside() {
        let followsVC = FollowsViewController()
        followsVC.followersOrFollowing = "Followers"
        followsVC.userID = creatoruid
        self.navigationController?.show(followsVC, sender: self)
    }
    
    @objc func followButtonTouchUpInside() {
        if isFollowing == false {
            FirebaseUtilities.followUser(uidToFollow: creatoruid, completion: {error in})
            self.isFollowing = true
        } else {
            FirebaseUtilities.unfollowerUser(uidToUnfollow: creatoruid, completion: {error in})
            self.isFollowing = false
        }
    }
    
    @objc func segmentedControlSwitched(_ segmentedControl: UISegmentedControl) {
        let indexSet = IndexSet(integersIn: 1...2)
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
                self.collectionNode.reloadSections(IndexSet(integersIn: 1...2))
            }
        }
    }
    
    // MARK: - CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        if indexPath.section == 0 {
            let headerCell = ExploreProfileHeaderNodeCell()
            
            headerCell.parentVC = self
            headerCell.topDaresPostPreviews = userPosts
            headerCell.topDaresCollectionNode.reloadData()
            
            headerCell.profileImage.url = URL(string: self.profile.pathToProfileImage ?? "")
            
            let nameAttributes = Utilities.createAttributes(color: .black, font: .boldSystemFont(ofSize: 26), shadow: false)
            let bioAndFollowLabelAttributes = Utilities.createAttributes(color: .black, font: .systemFont(ofSize: 14), shadow: false)
            let followCountAttributes = Utilities.createAttributes(color: .black, font: .boldSystemFont(ofSize: 14), shadow: false)
            let dareCountAttributes = Utilities.createAttributes(color: .lightGray, font: .systemFont(ofSize: 14), shadow: false)
            
            headerCell.nameLabel.attributedText = NSAttributedString(string: self.profile.fullName ?? "", attributes: nameAttributes)
            
            let bioText = (self.profile.bio ?? "").replacingOccurrences(of: "\n", with: "\n").replacingOccurrences(of: "\\n", with: "\n")
            headerCell.bioLabel.attributedText = NSAttributedString(string: bioText, attributes:
                bioAndFollowLabelAttributes)
            
            let followerButtonString = NSMutableAttributedString(string: String((self.profile.followerCount ?? 0)), attributes: followCountAttributes)
            let followersString = NSMutableAttributedString(string: " followers", attributes: bioAndFollowLabelAttributes)
            followerButtonString.append(followersString)
            
            headerCell.followerButton.addTarget(self, action: #selector(followersTouchUpInside), forControlEvents: .touchUpInside)
            headerCell.followerButton.setAttributedTitle(followerButtonString, for: .normal)
            
            let followingButtonString = NSMutableAttributedString(string: String((self.profile.followingCount ?? 0)), attributes: followCountAttributes)
            let followingString = NSMutableAttributedString(string: " following", attributes: bioAndFollowLabelAttributes)
            followingButtonString.append(followingString)
            
            headerCell.followingButton.addTarget(self, action: #selector(followingTouchUpInside), forControlEvents: .touchUpInside)
            headerCell.followingButton.setAttributedTitle(followingButtonString, for: .normal)
            
            headerCell.dareCountLabel.attributedText = NSAttributedString(string: "Dares completed: \(String(self.profile.daresCompleted ?? 0))", attributes: dareCountAttributes)
            
            headerCell.followButton.addTarget(self, action: #selector(followButtonTouchUpInside), forControlEvents: .touchUpInside)
            
            headerCell.followerCount = self.profile.followerCount ?? 0
            
            if isFollowing {
                let followingAttributes = Utilities.createAttributes(color: .orange, font: .boldSystemFont(ofSize: 18), shadow: false)
                headerCell.followButton.setAttributedTitle(NSAttributedString(string: "Following", attributes: followingAttributes), for: .normal)
                headerCell.followButton.backgroundColor = .white
                headerCell.followButton.borderWidth = 3.0
                headerCell.followButton.borderColor = UIColor.orange.cgColor
                headerCell.isFollowing = true
            } else {
                let followAttributes = Utilities.createAttributes(color: .white, font: .boldSystemFont(ofSize: 18), shadow: false)
                headerCell.followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
                headerCell.followButton.borderWidth = 0.0
                headerCell.followButton.backgroundColor = .orange
                headerCell.isFollowing = false
            }
            
            headerCell.segmentedView.addTarget(self, action: #selector(self.segmentedControlSwitched(_:)), for: .valueChanged)
                        
            return headerCell
        } else if indexPath.section == 1{
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
        } else if indexPath.section == 1 {
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
        } else if indexPath.section == 1 {
            let postSelectedVC = ProfilePostSelectedViewController()
            var postIDs = [""]
            for post in userPosts {
                postIDs.append(post.postID)
            }
            postSelectedVC.postIDs = postIDs
            postSelectedVC.postIndexPathRow = indexPath.row
            self.navigationController?.show(postSelectedVC, sender: self)
        } else {
            let cellID = userDares[indexPath.row].dareNameID
            self.view.showToast(message: cellID!)
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            if onCompleted {
                return userPosts.count
            } else {
                return 0
            }
        } else {
            if onCompleted {
                return 0
            } else {
                return userDares.count
            }
        }
    }
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 3
    }
}
