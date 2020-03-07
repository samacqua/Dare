//
//  DraftsCollectionCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class DraftsCollectionCell: UICollectionViewCell {
    
    // MARK: - Initalization and Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.backgroundColor = .gray
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10.0
    }
}
