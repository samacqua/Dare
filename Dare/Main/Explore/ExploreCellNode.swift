//
//  ExploreCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/21/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class ExploreCellNode: ASCellNode {
    
    var thumbnailImage = ASNetworkImageNode()
    
    // MARK: - Initialization and Setup
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        self.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), child: thumbnailImage)
    }

}
