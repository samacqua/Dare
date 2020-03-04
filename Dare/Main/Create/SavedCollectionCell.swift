//
//  SavedCollectionCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class SavedCollectionCell: UICollectionViewCell {
    
    var profileImageView: UIImageView!
    var dareLabel: UILabel!
    var attemptLabel: UILabel!
    var savedImageButton: UIButton!
    
    var isSaved: Bool = false
    
    //MARK: - Initalization and Setup
    
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
        
        let profileImage = UIImage(named: "email_phone_circle")
        profileImageView = UIImageView(image: profileImage)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 20.0
        addSubview(profileImageView)
        
        dareLabel = UILabel()
        dareLabel.text = "Example Dare"
        dareLabel.font = UIFont.boldSystemFont(ofSize: 17)
        dareLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dareLabel)
        
        attemptLabel = UILabel()
        attemptLabel.text = "100 attempts"
        attemptLabel.font = UIFont.systemFont(ofSize: 10)
        attemptLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(attemptLabel)
        
        savedImageButton = UIButton()
        let unsavedImage = UIImage(named: "Bookmark_Unselected")
        savedImageButton.setImage(unsavedImage, for: .normal)
        savedImageButton.imageView?.contentMode = .scaleAspectFit
        savedImageButton.translatesAutoresizingMaskIntoConstraints = false
        savedImageButton.addTarget(self, action: #selector(saveDarePressed), for: .touchUpInside)
        addSubview(savedImageButton)
    }
    
    // MARK: - Buttons and Actions
    
    @objc func saveDarePressed() {
        let savedImage = UIImage(named: "Bookmark_Selected")
        let unsavedImage = UIImage(named: "Bookmark_Unselected")
        if isSaved {
            savedImageButton.setImage(unsavedImage, for: .normal)
            isSaved = false
        } else if !isSaved {
            savedImageButton.setImage(savedImage, for: .normal)
            isSaved = true
        }
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            
            dareLabel.bottomAnchor.constraint(equalTo: self.centerYAnchor, constant: 3),
            dareLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            
            attemptLabel.topAnchor.constraint(equalTo: dareLabel.bottomAnchor, constant: 4),
            attemptLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            
            savedImageButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            savedImageButton.heightAnchor.constraint(equalToConstant: 30),
            savedImageButton.widthAnchor.constraint(equalToConstant: 30),
            savedImageButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
        ])
    }
}

