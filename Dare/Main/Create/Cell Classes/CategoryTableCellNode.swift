//
//  CategoryTableCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class CategoryTableCellNode: ASCellNode {
    
    var profileImageView = ASNetworkImageNode()
    var mainLabel = ASTextNode()
    var secondaryLabel = ASTextNode()
    var actionButton = ASButtonNode()
    
    var isSaved: Bool = false
    
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
        
        actionButton.setImage(UIImage(named: "Bookmark_Unselected"), for: .normal)
        actionButton.imageNode.contentMode = .scaleAspectFit
        actionButton.addTarget(self, action: #selector(bookmarkPressed), forControlEvents: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc func bookmarkPressed() {
        let savedImage = UIImage(named: "Bookmark_Selected")
        let unsavedImage = UIImage(named: "Bookmark_Unselected")
        if isSaved {
            actionButton.setImage(unsavedImage, for: .normal)
            isSaved = false
        } else if !isSaved {
            actionButton.setImage(savedImage, for: .normal)
            isSaved = true
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
        
        actionButton.style.spacingBefore = 10.0
        actionButton.style.spacingAfter = 10.0
        actionButton.style.preferredSize = CGSize(width: 25, height: 30)
        headerChildren.append(actionButton)
        
        headerStack.children = headerChildren
            
        return ASCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: headerStack)
    }
}
