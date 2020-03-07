//
//  ChangeUserInfoViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/1/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class ChangeUserInfoViewController: UIViewController {
    
    var userProperty: String = ""
    var userPropertyValue: String = ""
    
    var isAuthorized = false
    
    var continueButton: UIButton!
    var infoTextField: UITextField!
    
    // MARK: Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        setUpConstraints()
        hideKeyboardWhenTappedAround()
    }
    
    func setUpElements() {
        view.backgroundColor = .white
        self.title = userProperty
        
        infoTextField = UITextField()
        infoTextField.placeholder = userPropertyValue
        infoTextField.translatesAutoresizingMaskIntoConstraints = false
        Utilities.styleTextField(infoTextField)
        view.addSubview(infoTextField)
        
        continueButton = UIButton()
        continueButton.setTitle("Share", for: .normal)
        Utilities.styleFilledButton(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        view.addSubview(continueButton)
    }
    
    // MARK: Buttons and Actions
    
    @objc func continueButtonPressed() {
        
        FirebaseUtilities.updateUserProfileData(userProperty: userProperty, oldData: userPropertyValue, newData: self.infoTextField.text) { (error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            let layout = UICollectionViewFlowLayout()
            let profileVC = ProfileViewController()
            profileVC.collectionNode.reloadData()
            let editProfileVC = EditProfileViewController(collectionViewLayout: layout)
            editProfileVC.collectionView.reloadData()
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    // MARK: Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            infoTextField.heightAnchor.constraint(equalToConstant: 45),
            infoTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            infoTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            infoTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            
            continueButton.heightAnchor.constraint(equalToConstant: 60),
            continueButton.widthAnchor.constraint(equalToConstant: 374),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
    }
}
