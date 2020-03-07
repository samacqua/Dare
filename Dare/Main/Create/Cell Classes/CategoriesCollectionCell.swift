//
//  CategoriesCollectionCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class CategoriesCollectionCell: UICollectionViewCell {
    
    var categoryLabel: UILabel!
    
    // MARK: - Initialization and Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpElements()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10.0
        
        categoryLabel = UILabel()
        categoryLabel.textColor = .white
        categoryLabel.font = UIFont.boldSystemFont(ofSize: 18)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(categoryLabel)
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            categoryLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        ])
    }
}
