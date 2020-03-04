//
//  EditProfilePostCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class EditProfilePostCell: UICollectionViewCell {
    
    var infoNameLabel: UILabel!
    var userInfoLabel: UILabel!
    
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
        self.backgroundColor = .white
        
        infoNameLabel = UILabel()
        infoNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(infoNameLabel)
        
        userInfoLabel = UILabel()
        userInfoLabel.textColor = .gray
        userInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(userInfoLabel)
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            infoNameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            infoNameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            
            userInfoLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            userInfoLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        ])
    }
}
