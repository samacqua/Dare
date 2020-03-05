//
//  ActivityCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/18/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseAuth
import FirebaseFirestore

class ActivityCellNode: ASCellNode {
    
    var parentVC: UIViewController!
    
    var profileImageView = ASNetworkImageNode()
    var activityLabel = ASTextNode()
    var timestampLabel = ASTextNode()
    
    var postThumbnailImageView = ASNetworkImageNode()
    var followButton = ASButtonNode()
    
    var isFollowing = false
    var type: String!
    
    var otheruid: String!
    let uid = Auth.auth().currentUser!.uid
    let database = Firestore.firestore()
    
    let followAttributes = Utilities.createAttributes(color: .white, fontSize: 16, bold: true, shadow: false)
    let followingAttributes = Utilities.createAttributes(color: .orange, fontSize: 16, bold: true, shadow: false)
    
    // MARK: - Initalization and Setup
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
    }
    
    override func didLoad() {
        setUpElements()
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 45 / 2
        
        let userTapped = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        activityLabel.view.isUserInteractionEnabled = true
        activityLabel.view.addGestureRecognizer(userTapped)
        let profileImageTapped = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.view.isUserInteractionEnabled = true
        profileImageView.view.addGestureRecognizer(profileImageTapped)
        
        if type == "follow" {
            postThumbnailImageView.isHidden = true
            
            followButton.isHidden = false
            followButton.addTarget(self, action: #selector(followButtonTouchUpInside), forControlEvents: .touchUpInside)
            followButton.cornerRoundingType = .defaultSlowCALayer
            followButton.cornerRadius = 5.0
            
            if isFollowing {
                followButton.setAttributedTitle(NSAttributedString(string: "Following", attributes: followingAttributes), for: .normal)
                followButton.backgroundColor = .white
                followButton.borderWidth = 2.0
                followButton.borderColor = UIColor.orange.cgColor
            } else {
                followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
                followButton.borderWidth = 0.0
                followButton.backgroundColor = .orange
            }
        } else {
            followButton.isHidden = true
            
            postThumbnailImageView.isHidden = false
            postThumbnailImageView.backgroundColor = .lightGray
        }
    }
    
    // MARK: - Actions
    
    @objc func profileTapped() {
        let exploreProfileVC = ExploreProfileViewController()
        exploreProfileVC.creatoruid = otheruid
        parentVC.self.navigationController?.show(exploreProfileVC, sender: self)
    }
    
    @objc func followButtonTouchUpInside() {
        if isFollowing {
            followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
            followButton.borderWidth = 0.0
            followButton.backgroundColor = .orange
            
            FirebaseUtilities.unfollowerUser(uidToUnfollow: otheruid) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            }
            self.isFollowing = false
        } else {
            followButton.setAttributedTitle(NSAttributedString(string: "Following", attributes: followingAttributes), for: .normal)
            followButton.backgroundColor = .white
            followButton.borderWidth = 2.0
            followButton.borderColor = UIColor.orange.cgColor
            
            FirebaseUtilities.followUser(uidToFollow: otheruid) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            }
            self.isFollowing = true
        }
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        var headerChildren: [ASLayoutElement] = []
        
        let headerStack = ASStackLayoutSpec.horizontal()
        headerStack.alignItems = .center
        
        profileImageView.style.preferredSize = CGSize(width: 45, height: 45)
        let profileImageInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        headerChildren.append(ASInsetLayoutSpec(insets: profileImageInset, child: profileImageView))
        
        let descriptionTimeStack = ASStackLayoutSpec.vertical()
        descriptionTimeStack.children = [activityLabel, timestampLabel]
        descriptionTimeStack.style.flexShrink = 1.0
        headerChildren.append(descriptionTimeStack)
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        headerChildren.append(spacer)
        
        if type == "follow" {
            followButton.style.spacingBefore = 10.0
            followButton.style.spacingAfter = 10.0
            followButton.style.preferredSize = CGSize(width: 100, height: 30)
            headerChildren.append(followButton)
        } else {
            postThumbnailImageView.style.spacingBefore = 10.0
            postThumbnailImageView.style.spacingAfter = 10.0
            postThumbnailImageView.style.preferredSize = CGSize(width: 40, height: 50)
            headerChildren.append(postThumbnailImageView)
        }
        
        headerStack.children = headerChildren
        return ASCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: headerStack)
    }
}

