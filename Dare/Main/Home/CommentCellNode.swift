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
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        var headerChildren: [ASLayoutElement] = []
        
        let headerStack = ASStackLayoutSpec.horizontal()
        headerStack.alignItems = .center
        
        profileImageView.style.preferredSize = CGSize(width: 45, height: 45)
        profileImageView.style.spacingAfter = 10.0
        headerChildren.append(profileImageView)
        
        let dareLabelCountSpec = ASStackLayoutSpec.vertical()
        dareLabelCountSpec.children = [usernameLabel, commentLabel]
        dareLabelCountSpec.style.flexShrink = 1.0
        headerChildren.append(dareLabelCountSpec)
        
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        headerChildren.append(spacer)
        
        headerStack.children = headerChildren
            
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10), child: headerStack)
    }
}
