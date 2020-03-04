//
//  TopDaresNodeCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 3/3/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class TopDaresNodeCell: ASCellNode {
    
    var thumbnailImage = ASNetworkImageNode()
    
    // MARK: - Initialization and Setup
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = .lightGray
        self.layer.cornerRadius = 30
        self.layer.masksToBounds = true
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), child: thumbnailImage)
    }

}

