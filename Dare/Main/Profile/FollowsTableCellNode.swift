//
//  FollowsTableCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/10/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseAuth
import FirebaseFirestore

class FollowsTableCellNode: ASCellNode {
    
    var profileImageView = ASNetworkImageNode()
    var mainLabel = ASTextNode()
    var secondaryLabel = ASTextNode()
    var followButton = ASButtonNode()
    
    var isFollowing: Bool = false
    var isCurrentUser: Bool = false
    
    var otheruid: String!
    let uid = Auth.auth().currentUser!.uid
    var currentUserUsername: String!
    
    let database = Firestore.firestore()
    
    let followAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.white,
        .font : UIFont.boldSystemFont(ofSize: 16)
    ]
    
    let followingAttributes: [NSAttributedString.Key: Any] = [
         .foregroundColor : UIColor.orange,
         .font : UIFont.boldSystemFont(ofSize: 16)
     ]
    
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
        
        if isCurrentUser {
            followButton.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc func followButtonTouchUpInside() {
        print("is following?", isFollowing)
        if isFollowing {
            followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
            followButton.borderWidth = 0.0
            followButton.backgroundColor = .orange
            
            FirebaseUtilities.unfollowerUser(uidToUnfollow: otheruid, completion: { error in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            })
            self.isFollowing = false
        } else {
            followButton.setAttributedTitle(NSAttributedString(string: "Following", attributes: followingAttributes), for: .normal)
            followButton.backgroundColor = .white
            followButton.borderWidth = 2.0
            followButton.borderColor = UIColor.orange.cgColor
            
            FirebaseUtilities.followUser(uidToFollow: otheruid, completion: {error in })
            self.isFollowing = false
        }
    }
    
    // MARK: - Functions
    
    func getUserPostIDs(completion: @escaping(_ postIDs:[String]) -> ()) {
        database.collection("users").document(otheruid).collection("posts").getDocuments { (snapshot, error) in
            if error != nil {
                print("Error retrieving user posts:", error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var postIDs = [String]()
            
            for document in documents {
                
                let id = document.documentID
                postIDs.append(id)
            }
            return completion(postIDs)
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
        
        let dareLabelCountSpec = ASStackLayoutSpec.vertical()
        dareLabelCountSpec.children = [mainLabel, secondaryLabel]
        dareLabelCountSpec.style.flexShrink = 1.0
        headerChildren.append(dareLabelCountSpec)
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        headerChildren.append(spacer)
        
        followButton.style.spacingBefore = 10.0
        followButton.style.spacingAfter = 10.0
        followButton.style.preferredSize = CGSize(width: 100, height: 30)
        headerChildren.append(followButton)
        
        headerStack.children = headerChildren
            
        return ASCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: headerStack)
    }
}
