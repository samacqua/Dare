//
//  EmailPasswordSignUpViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class EmailPasswordSignUpViewController: UIViewController {
    
    var exitButton: UIButton!
    var faqButton: UIButton!
    var logoImageView: UIImageView!
    var setPasswordLabel: UILabel!
    var passwordTextField: UITextField!
    var confirmPasswordTextField: UITextField!
    var continueButton: UIButton!
    
    var email: String!
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        setUpElements()
        setUpConstraints()
        self.hideKeyboardWhenTappedAround()
    }
    
    var textViewY: CGFloat!
    var initial = true
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initial {
            textViewY = confirmPasswordTextField.frame.maxY
            initial = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var passwordTopConstraint: NSLayoutConstraint?
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
        
        setPasswordLabel = UILabel()
        setPasswordLabel.text = "Enter your password"
        setPasswordLabel.textAlignment = .center
        setPasswordLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        setPasswordLabel.adjustsFontSizeToFitWidth = true
        setPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setPasswordLabel)

        passwordTextField = UITextField()
        passwordTextField.placeholder = "password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldChanged), for: .editingChanged)
        passwordTextField.layer.zPosition = 1.0
        passwordTextField.backgroundColor = .white
        passwordTopConstraint = NSLayoutConstraint(item: passwordTextField!, attribute: .top, relatedBy: .equal, toItem: setPasswordLabel, attribute: .bottom, multiplier: 1.0, constant: 20.0)
        view.addSubview(passwordTextField)
        view.addConstraint(passwordTopConstraint!)

        confirmPasswordTextField = UITextField()
        confirmPasswordTextField.placeholder = "reenter password"
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmPasswordTextField.addTarget(self, action: #selector(confirmPasswordTextFieldChanged), for: .editingChanged)
        
        view.addSubview(confirmPasswordTextField)

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
        
        Utilities.styleTextField(passwordTextField)
        Utilities.styleTextField(confirmPasswordTextField)
        Utilities.styleHollowButtonColored(continueButton)
        continueButton.isEnabled = false
        continueButton.layer.borderColor = UIColor.lightGray.cgColor
        
        bottomConstraint = NSLayoutConstraint(item: confirmPasswordTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
    }
    
    // MARK: - Actions
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let rect = keyboardFrame.cgRectValue
                
                let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
                
                if isKeyboardShowing {
                    view.removeConstraint(passwordTopConstraint!)
                    bottomConstraint?.constant = -rect.height
                    view.addConstraint(bottomConstraint!)
                } else {
                    view.removeConstraint(bottomConstraint!)
                    view.addConstraint(passwordTopConstraint!)
                    bottomConstraint?.constant = self.textViewY - self.view.bounds.height
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
        print("faq pressed")
    }
    
    @objc func passwordTextFieldChanged() {
        enableDisableContinueButton()
    }
    
    @objc func confirmPasswordTextFieldChanged() {
        enableDisableContinueButton()
    }
    
    @objc func continueTouchUpInside() {
        if validatePassword() == nil {
            let password = passwordTextField.text!
            FirebaseUtilities.handleEmailSignUp(email: email, password: password) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                } else {
                    let mainVC = MainTabBarController()
                    mainVC.modalPresentationStyle = .fullScreen
                    self.present(mainVC, animated: true, completion: nil)
                }
            }
        } else {
            self.view.showToast(message: validatePassword()!)
            return
        }
    }
    
    // MARK: - Functions
    
    func validatePassword() -> String? {
        let password = passwordTextField.text
        let confirmPassword = confirmPasswordTextField.text
        if password == "" {
            return "Please enter a password"
        } else if confirmPassword == "" {
            return "Please confirm your password"
        } else if confirmPassword != password {
            return "The two passwords do not match"
        } else if Utilities.isPasswordValid(password) != true {
            return "Please ensure your password is at least 8 characters long."
        }
        return nil
    }
    
    func enableDisableContinueButton() {
        let password = passwordTextField.text
        let passwordConfirm = confirmPasswordTextField.text
        if password != nil && passwordConfirm != nil {
            continueButton.isEnabled = true
            continueButton.layer.borderColor = UIColor.orange.cgColor
        } else {
            continueButton.isEnabled = false
            continueButton.layer.borderColor = UIColor.lightGray.cgColor
        }
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
        
        setPasswordLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
        setPasswordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        
        passwordTextField.heightAnchor.constraint(equalToConstant: 45),
        passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
        passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
        
        confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 45),
        confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
        confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
        confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
        
        continueButton.heightAnchor.constraint(equalToConstant: 45),
        continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
        continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
        continueButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 30)
        ])
    }
}
