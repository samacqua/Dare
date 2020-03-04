//
//  EditProfilePictureHeaderCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class EditProfilePictureHeaderCell: UICollectionViewCell {
    
    var profileImage: UIButton!
    var changeProfileImageButton: UIButton!
    
    // MARK: - Initalize and Setup
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        
        setUpElements()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        profileImage = UIButton()
        let image = UIImage(named: "email_phone_circle")
        profileImage.setImage(image, for: .normal)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.layer.cornerRadius = 50
        profileImage.clipsToBounds = true
        addSubview(profileImage)
        
        changeProfileImageButton = UIButton()
        changeProfileImageButton.setTitle("Change profile image", for: .normal)
        changeProfileImageButton.setTitleColor(.darkGray, for: .normal)
        changeProfileImageButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(changeProfileImageButton)
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            profileImage.heightAnchor.constraint(equalToConstant: 100),
            profileImage.widthAnchor.constraint(equalToConstant: 100),
            profileImage.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            profileImage.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            changeProfileImageButton.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 10),
            changeProfileImageButton.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
}
