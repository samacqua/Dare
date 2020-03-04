//
//  PhoneConfirmationViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/22/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class PhoneConfirmationViewController: UIViewController {
    
    // TODO: passcode view instead of normal textfield
    
    var exitButton: UIButton!
    var faqButton: UIButton!
    var logoImageView: UIImageView!
    var mainTitleLabel: UILabel!
    var moreInfoLabel: UILabel!
    var confirmationCodeTextField: UITextField!
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
        mainTitleLabel.text = "Enter Verification ID"
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        mainTitleLabel.adjustsFontSizeToFitWidth = true
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainTitleLabel)
        
        moreInfoLabel = UILabel()
        moreInfoLabel.text = "A code should have been sent to your entered phone number, enter it below."
        moreInfoLabel.textAlignment = .center
        moreInfoLabel.numberOfLines = 0
        moreInfoLabel.textColor = .gray
        moreInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(moreInfoLabel)
        
        confirmationCodeTextField = UITextField()
        confirmationCodeTextField.placeholder = "password"
        confirmationCodeTextField.isSecureTextEntry = true
        confirmationCodeTextField.keyboardType = .numberPad
        Utilities.styleTextField(confirmationCodeTextField)
        confirmationCodeTextField.textContentType = .oneTimeCode
        confirmationCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmationCodeTextField.addTarget(self, action: #selector(confirmationCodeTextFieldChanged), for: .editingChanged)
        view.addSubview(confirmationCodeTextField)
        
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
    
    @objc func confirmationCodeTextFieldChanged() {
        if confirmationCodeTextField.text == "" {
            enableContinueButton(isEnabled: false)
        } else if confirmationCodeTextField.text != "" {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func continueTouchUpInside() {

        guard let verificationCode = confirmationCodeTextField.text else { return }
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        FirebaseUtilities.handlePhoneAuthentication(credential: credential) { (error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            let homeVC = MainTabBarController()
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Functions
    
    func validatePassword() -> String? {
        let password = confirmationCodeTextField.text
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
            mainTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            mainTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            
            moreInfoLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 16),
            moreInfoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            moreInfoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            confirmationCodeTextField.heightAnchor.constraint(equalToConstant: 45),
            confirmationCodeTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            confirmationCodeTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            confirmationCodeTextField.topAnchor.constraint(equalTo: moreInfoLabel.bottomAnchor, constant: 20),
            
            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: confirmationCodeTextField.bottomAnchor, constant: 30)
        ])
    }
}

