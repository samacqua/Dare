//
//  EmailPhoneLoginViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth
import FlagPhoneNumber

class EmailPhoneLoginViewController: UIViewController, FPNTextFieldDelegate {
    
    var exitButton: UIButton!
    var faqButton: UIButton!
    var logoImageView: UIImageView!
    var segmentedControl: UISegmentedControl!
    var enterInfoLabel: UILabel!
    var emailTextField: UITextField!
    var phoneNumberTextField = FPNTextField()
    var passwordTextField: UITextField!
    var continueButton: UIButton!
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        setUpElements()
        setUpConstraints()
        self.hideKeyboardWhenTappedAround()
    }
    
    var passwordTextViewY: CGFloat!
    var phoneTextViewY: CGFloat!
    var initial = true
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initial {
            passwordTextViewY = passwordTextField.frame.maxY
            phoneTextViewY = phoneNumberTextField.frame.maxY
            initial = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var emailTopConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?

    func setUpElements() {
        view.backgroundColor = .white
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        view.addSubview(exitButton)
        
        faqButton = UIButton(type: .system)
        let faqImage = UIImage(named: "FAQ_icon")
        faqButton.setImage(faqImage, for: .normal)
        faqButton.translatesAutoresizingMaskIntoConstraints = false
        faqButton.addTarget(self, action: #selector(faqButtonTouchUpInside), for: .touchUpInside)
        view.addSubview(faqButton)
        
        let dareLogo = UIImage(named: "RiskLogoTransparentNoText")
        logoImageView = UIImageView(image: dareLogo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        segmentedControl = UISegmentedControl(items: ["Email", "Phone"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentedControlSwitched), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        enterInfoLabel = UILabel()
        enterInfoLabel.text = "Enter your email"
        enterInfoLabel.textAlignment = .center
        enterInfoLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        enterInfoLabel.adjustsFontSizeToFitWidth = true
        enterInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterInfoLabel)
        
        emailTextField = UITextField()
        emailTextField.placeholder = "email"
        emailTextField.keyboardType = .emailAddress
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.addTarget(self, action: #selector(emailTextFieldChanged), for: .editingChanged)
        emailTextField.layer.zPosition = 1.0
        emailTextField.backgroundColor = .white
        emailTopConstraint = NSLayoutConstraint(item: emailTextField!, attribute: .top, relatedBy: .equal, toItem: enterInfoLabel, attribute: .bottom, multiplier: 1.0, constant: 20.0)

        view.addSubview(emailTextField)
        view.addConstraint(emailTopConstraint!)

        phoneNumberTextField.isHidden = true
        phoneNumberTextField.keyboardType = .phonePad
        phoneNumberTextField.translatesAutoresizingMaskIntoConstraints = false
        phoneNumberTextField.delegate = self as FPNTextFieldDelegate
        phoneNumberTextField.layer.zPosition = 1.0
        phoneNumberTextField.backgroundColor = .white
        phoneNumberTextField.addTarget(self, action: #selector(phoneTextFieldChanged), for: .editingChanged)
        phoneNumberTextField.layer.zPosition = 1.0
        phoneNumberTextField.backgroundColor = .white
        view.addSubview(phoneNumberTextField)
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldChanged), for: .editingChanged)
        passwordTextField.layer.zPosition = 1.0
        passwordTextField.backgroundColor = .white
        view.addSubview(passwordTextField)
        
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitle("Continue", for: .disabled)
        continueButton.isEnabled = false
        Utilities.styleHollowButtonColored(continueButton)
        continueButton.tintColor = UIColor.lightGray
        continueButton.layer.borderColor = UIColor.lightGray.cgColor
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueTouchUpInside), for: .touchUpInside)
        view.addSubview(continueButton)
        
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        
        bottomConstraint = NSLayoutConstraint(item: passwordTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
    }
    
    // MARK: - Actions
        
    @objc func handleKeyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let rect = keyboardFrame.cgRectValue
                
                let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
                
                if isKeyboardShowing {
                    view.removeConstraint(emailTopConstraint!)
                    bottomConstraint?.constant = -rect.height
                    view.addConstraint(bottomConstraint!)
                } else {
                    view.removeConstraint(bottomConstraint!)
                    view.addConstraint(emailTopConstraint!)
                    bottomConstraint?.constant = (segmentedControl.selectedSegmentIndex == 0 ? self.passwordTextViewY - self.view.bounds.height: self.phoneTextViewY - self.view.bounds.height)
                    view.addConstraint(bottomConstraint!)
                }
                
                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func faqButtonTouchUpInside() {
        print("FAQ pressed")
    }
    
    @objc func segmentedControlSwitched() {
        enableContinueButton(isEnabled: false)
        emailTextField.text = ""
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            enterInfoLabel.text = "Enter your email"
            emailTextField.isHidden = false
            phoneNumberTextField.isHidden = true
            passwordTextField.isHidden = false
            
            bottomConstraint = NSLayoutConstraint(item: passwordTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        case 1:
            enterInfoLabel.text = "Enter your phone number"
            emailTextField.isHidden = true
            phoneNumberTextField.isHidden = false
            passwordTextField.isHidden = true
            
            bottomConstraint = NSLayoutConstraint(item: phoneNumberTextField, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        default:
            break
        }
    }
    
    @objc func emailTextFieldChanged(_ textField: UITextField) {
        if emailTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else if emailTextField.text != nil {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func phoneTextFieldChanged(_ textField: UITextField) {
        if phoneNumberTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else if phoneNumberTextField.text != nil {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func passwordTextFieldChanged(_ textField: UITextField) {
        print("password changed")
    }
    
    @objc func continueTouchUpInside() {
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                if validatePassword() != nil || validateEmail() != nil {
                    validatePassword() != nil ? self.view.showToast(message: validatePassword()!): self.view.showToast(message: validateEmail()!)
                }
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
            case 1:
                if validatePhoneNumber() != nil {
                    self.view.showToast(message: validatePhoneNumber()!)
                } else {
                   let phoneNumber = phoneNumberTextField.getFormattedPhoneNumber(format: .E164)!
                    PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
                        if error != nil {
                            print(error!)
                            self.view.showToast(message: error!.localizedDescription)
                        } else {
                            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                            self.navigationController?.show(PhoneConfirmationViewController(), sender: self)
                            print(verificationID!)
                        }
                    }
                }
            default:
                break
            }
    }
    
    // MARK: - Functions
    
    func validateEmail() -> String? {
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if email == "" {
            return "Please enter your email."
        } else if Utilities.isEmailValid(email) == false {
            return "Please enter a valid email"
        }
        return nil
    }
    
    func validatePhoneNumber() -> String? {
        if phoneNumberTextField.text == "" {
            return "Please enter your phone number."
        } else if phoneNumberTextField.getRawPhoneNumber() == nil {
            return "Please enter valid phone number"
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
    
    func validatePassword() -> String? {
        let password = passwordTextField.text
        if password == "" {
            return "Please enter a password"
        } else if Utilities.isPasswordValid(password) != true {
            return "Please ensure your password is at least 8 characters long"
        }
        return nil
    }
    
    func fpnDidSelectCountry(name: String, dialCode: String, code: String) {
        // needed to conform
        //        print(name, dialCode, code)
    }
    
    func fpnDidValidatePhoneNumber(textField: FPNTextField, isValid: Bool) {
        // needed to conform, and would be helpful if could figure out
        //        if isValid {
        //            let phoneNumber = phoneNumberTextField.getRawPhoneNumber()
        //           print("phoneNumber: ", phoneNumber)
        //        } else {
        //           print("is not valid")
        //        }
    }

    func fpnDisplayCountryList() {
        // needed to conform
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            exitButton.heightAnchor.constraint(equalToConstant: 33),
            exitButton.widthAnchor.constraint(equalToConstant: 33),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            faqButton.heightAnchor.constraint(equalToConstant: 33),
            faqButton.widthAnchor.constraint(equalToConstant: 33),
            faqButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            faqButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            logoImageView.heightAnchor.constraint(equalToConstant: 171),
            logoImageView.widthAnchor.constraint(equalToConstant: 171),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 112),
            segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -112),
            segmentedControl.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
            
            enterInfoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 45),
            enterInfoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -45),
            enterInfoLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 30),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 45),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 45),
            phoneNumberTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            phoneNumberTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            phoneNumberTextField.topAnchor.constraint(equalTo: emailTextField.topAnchor),
            
            passwordTextField.heightAnchor.constraint(equalToConstant: 45),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            
            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30)
        ])
    }
}
