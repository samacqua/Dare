//
//  DarePageHeaderNodeCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/4/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class DarePageHeaderNodeCell: ASCellNode {
    
    var dareImage = ASNetworkImageNode()
    var dareLabel = ASTextNode()
    var userCreatorButton = ASButtonNode()
    var dareCountLabel = ASTextNode()
    var bookmarkButton = ASButtonNode()
    
    var dareID: String!
    var creatoruid: String!
    
    var isSaved: Bool = false
    
    // MARK: - Initialization and Setup
    
    override init() {
        super.init()
        
        self.automaticallyManagesSubnodes = true
        setUpElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        dareImage.layer.cornerRadius = 40.0
        dareImage.layer.masksToBounds = true
        dareImage.layer.backgroundColor = UIColor.gray.cgColor
        
        bookmarkButton.setImage(UIImage(named: "Bookmark_Unselected"), for: .normal)
        bookmarkButton.imageNode.contentMode = .scaleAspectFit
        bookmarkButton.style.preferredSize = CGSize(width: 25, height: 30)
        bookmarkButton.addTarget(self, action: #selector(bookmarkPressed), forControlEvents: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc func bookmarkPressed() {
        let savedImage = UIImage(named: "Bookmark_Selected")
        let unsavedImage = UIImage(named: "Bookmark_Unselected")
        if isSaved {
            bookmarkButton.setImage(unsavedImage, for: .normal)
            isSaved = false
        } else if !isSaved {
            bookmarkButton.setImage(savedImage, for: .normal)
            isSaved = true
        }
    }
    
    // MARK: Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        dareImage.style.preferredSize.height = 80.0
        dareImage.style.preferredSize.width = 80.0
        
        let infoStack = ASStackLayoutSpec(direction: .vertical, spacing: 8, justifyContent: .start, alignItems: .start, children: [dareLabel, userCreatorButton, dareCountLabel])
        
        let totalStack = ASStackLayoutSpec(direction: .horizontal, spacing: 15, justifyContent: .start, alignItems: .start, children: [dareImage, infoStack, bookmarkButton])
        
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 15, left: 15, bottom: CGFloat.infinity, right: 100), child: totalStack)
    }
}

