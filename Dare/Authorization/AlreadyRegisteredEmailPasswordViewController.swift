//
//  AlreadyRegisteredEmailPasswordViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth

class AlreadyRegisteredEmailPasswordViewController: UIViewController {
    
    var exitButton: UIButton!
    var faqButton: UIButton!
    var logoImageView: UIImageView!
    var mainTitleLabel: UILabel!
    var moreInfoLabel: UILabel!
    var passwordTextField: UITextField!
    var continueButton: UIButton!
        
    var email = "email@web.com"
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElements()
        setUpConstraints()
        self.hideKeyboardWhenTappedAround()
    }
    
    func setUpElements() {
        view.backgroundColor = .white
        
        faqButton = UIButton(type: .system)
        let faqImage = UIImage(named: "FAQ_icon")
        faqButton.setImage(faqImage, for: .normal)
        faqButton.translatesAutoresizingMaskIntoConstraints = false
        faqButton.addTarget(self, action: #selector(faqButtonTouchUpInside), for: .touchUpInside)
        view.addSubview(faqButton)
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        view.addSubview(exitButton)
        
        let dareLogo = UIImage(named: "RiskLogoTransparentNoText")
        logoImageView = UIImageView(image: dareLogo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        mainTitleLabel = UILabel()
        mainTitleLabel.text = "Login to Dare"
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainTitleLabel)
        
        moreInfoLabel = UILabel()
        moreInfoLabel.text = "Manage your account, check notifications, comment on Dares, and more."
        moreInfoLabel.textAlignment = .center
        moreInfoLabel.numberOfLines = 0
        moreInfoLabel.textColor = .gray
        moreInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(moreInfoLabel)
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "password"
        passwordTextField.isSecureTextEntry = true
        Utilities.styleTextField(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldChanged), for: .editingChanged)
        view.addSubview(passwordTextField)
        
        continueButton = UIButton(type: .system)
        continueButton.isEnabled = false
        continueButton.tintColor = UIColor.lightGray
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitle("Continue", for: .disabled)
        Utilities.styleHollowButtonColored(continueButton)
        continueButton.layer.borderColor = UIColor.lightGray.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTouchUpInside), for: .touchUpInside)
        view.addSubview(continueButton)
    }
    
    // MARK: - Actions
    
    @objc func faqButtonTouchUpInside() {
        print("faq pressed")
    }
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func passwordTextFieldChanged() {
        if passwordTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else if passwordTextField.text != nil {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func continueTouchUpInside() {
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if validatePassword() != nil {
            print(validatePassword()!)
            self.view.showToast(message: validatePassword()!)
        } else {
            Auth.auth().signIn(withEmail: email, password: password!) { (result, error) in
                if error != nil {
                    print("Error signing in: ", error!)
                    self.view.showToast(message: error!.localizedDescription)
                } else {
                    let homeVC = MainTabBarController()
                    homeVC.modalPresentationStyle = .fullScreen
                    self.present(homeVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Functions
    
    func validatePassword() -> String? {
        let password = passwordTextField.text
        if password == "" {
            return "Please enter a password"
        } else if Utilities.isPasswordValid(password) != true {
            return "Please ensure your password is at least 8 characters long"
        }
        return nil
    }
    
    func enableContinueButton(isEnabled: Bool) {
        if !isEnabled {
            continueButton.isEnabled = false
            continueButton.tintColor = UIColor.lightGray
            continueButton.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            continueButton.isEnabled = true
            continueButton.tintColor = UIColor.orange
            continueButton.layer.borderColor = UIColor.orange.cgColor
        }
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            exitButton.heightAnchor.constraint(equalToConstant: 33),
            exitButton.widthAnchor.constraint(equalToConstant: 33),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            faqButton.heightAnchor.constraint(equalToConstant: 33),
            faqButton.widthAnchor.constraint(equalToConstant: 33),
            faqButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            faqButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            logoImageView.heightAnchor.constraint(equalToConstant: 171),
            logoImageView.widthAnchor.constraint(equalToConstant: 171),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            mainTitleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            mainTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 79),
            mainTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -79),
            
            moreInfoLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 16),
            moreInfoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            moreInfoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            passwordTextField.heightAnchor.constraint(equalToConstant: 45),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            passwordTextField.topAnchor.constraint(equalTo: moreInfoLabel.bottomAnchor, constant: 20),
            
            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30)
        ])
    }
}
