//
//  EditProfileHeaderCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class EditProfileHeaderCell: UICollectionViewCell {
    
    var title: UILabel!
    
    // MARK: - Initialize and Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpElements()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.backgroundColor = .white

        title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            title.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10)
        ])
    }
    
}
