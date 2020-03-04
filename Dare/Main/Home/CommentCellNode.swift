//
//  CommentCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class CommentCellNode: ASCellNode {
    
    var profileImageView = ASNetworkImageNode()
    var usernameLabel = ASTextNode()
    var commentLabel = ASTextNode()
    var likeButton = ASButtonNode()
    var likeCountLabel = ASTextNode()
        
    // MARK: - Initalization and Setup
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        setUpElements()
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 45 / 2
        
        let likeImage = ASImageNodeTintColorModificationBlock(.red)(UIImage(named: "like_filled")!)
        likeButton.setImage(likeImage, for: .normal)
        likeButton.imageNode.contentMode = .scaleAspectFit
        likeButton.addTarget(self, action: #selector(likeButtonPressed), forControlEvents: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc func likeButtonPressed() {
        print("like button pressed")
    }
    
    // MARK: - Functions
    
    func likeComment() {
        
    }
    
    func unlikeComment() {
        
    }
    
    func checkIfLiked() {
        
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
        dareLabelCountSpec.children = [usernameLabel, commentLabel]
        dareLabelCountSpec.style.flexShrink = 1.0
        headerChildren.append(dareLabelCountSpec)
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        headerChildren.append(spacer)
        
        likeCountLabel.style.spacingBefore = 10.0
        likeCountLabel.style.spacingAfter = 5.0
        headerChildren.append(likeCountLabel)
        
        likeButton.style.spacingBefore = 5.0
        likeButton.style.spacingAfter = 10.0
        likeButton.style.preferredSize = CGSize(width: 15, height: 15)
        headerChildren.append(likeButton)
        
        headerStack.children = headerChildren
            
        return ASCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: headerStack)
    }
}
