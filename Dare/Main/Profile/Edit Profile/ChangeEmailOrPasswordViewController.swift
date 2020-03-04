//
//  ChangeEmailOrPasswordViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/26/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth

class ChangeEmailOrPasswordViewController: UIViewController {
    
    var isEmail: Bool!
    
    var logoImageView: UIImageView!
    var enterInfoLabel: UILabel!
    var infoTextField: UITextField!
    var confirmInfoTextField: UITextField!
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
    
    var confirmInfoTextViewY: CGFloat!
    var initial = true
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initial {
            confirmInfoTextViewY = confirmInfoTextField.frame.maxY
            initial = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var infoTopConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?

    func setUpElements() {
        view.backgroundColor = .white
        
        let dareLogo = UIImage(named: "RiskLogoTransparentNoText")
        logoImageView = UIImageView(image: dareLogo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        enterInfoLabel = UILabel()
        enterInfoLabel.text = (isEmail ? "Enter your new email" : "Enter your new password")
        enterInfoLabel.textAlignment = .center
        enterInfoLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        enterInfoLabel.adjustsFontSizeToFitWidth = true
        enterInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterInfoLabel)

        infoTextField = UITextField()
        infoTextField.translatesAutoresizingMaskIntoConstraints = false
        infoTextField.addTarget(self, action: #selector(infoTextFieldChanged), for: .editingChanged)
        infoTextField.layer.zPosition = 1.0
        infoTextField.backgroundColor = .white
        infoTopConstraint = NSLayoutConstraint(item: infoTextField!, attribute: .top, relatedBy: .equal, toItem: enterInfoLabel, attribute: .bottom, multiplier: 1.0, constant: 20.0)
        if isEmail {
            infoTextField.placeholder = "email"
            infoTextField.isSecureTextEntry = false
        } else {
            infoTextField.placeholder = "password"
            infoTextField.isSecureTextEntry = true
        }
        view.addSubview(infoTextField)
        view.addConstraint(infoTopConstraint!)
        
        confirmInfoTextField = UITextField()
        confirmInfoTextField.translatesAutoresizingMaskIntoConstraints = false
        confirmInfoTextField.layer.zPosition = 1.0
        confirmInfoTextField.backgroundColor = .white
        if isEmail {
            confirmInfoTextField.placeholder = "confirm email"
            confirmInfoTextField.isSecureTextEntry = false
        } else {
            confirmInfoTextField.placeholder = "confirm password"
            confirmInfoTextField.isSecureTextEntry = true
        }
        view.addSubview(confirmInfoTextField)
        
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
        
        Utilities.styleTextField(infoTextField)
        Utilities.styleTextField(confirmInfoTextField)
        
        bottomConstraint = NSLayoutConstraint(item: confirmInfoTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
    }
    
    // MARK: - Actions
        
    @objc func handleKeyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let rect = keyboardFrame.cgRectValue
                
                let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
                
                if isKeyboardShowing {
                    view.removeConstraint(infoTopConstraint!)
                    bottomConstraint?.constant = -rect.height
                    view.addConstraint(bottomConstraint!)
                } else {
                    view.removeConstraint(bottomConstraint!)
                    view.addConstraint(infoTopConstraint!)
                }
                
                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    @objc func infoTextFieldChanged(_ textField: UITextField) {
        if infoTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else if infoTextField.text != nil {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func continueTouchUpInside() {
        let password = infoTextField.text!
        guard let currentUser = Auth.auth().currentUser else { return }
        switch isEmail {
        case true:
            if validateEmail() != nil {
                self.view.showToast(message: validateEmail()!)
            } else {
                FirebaseUtilities.updateUserEmail(newEmail: infoTextField.text!) { (error) in
                    if error != nil {
                        self.view.showToast(message: error!.localizedDescription)
                    } else {
                        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                    }
                }
            }
        case false:
            if validatePassword() != nil {
                self.view.showToast(message: validatePassword()!)
            } else {
                currentUser.updatePassword(to: password, completion: { (updatePasswordError) in
                    if updatePasswordError != nil {
                        self.view.showToast(message: updatePasswordError!.localizedDescription)
                    } else {
                        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                    }
                })
            }
        default:
            break
        }
    }
    
    // MARK: - Functions
    
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
    
    func validateEmail() -> String? {
        let email = infoTextField.text
        let confirmEmail = confirmInfoTextField.text
        if email == "" {
            return "Please enter your email"
        } else if email != confirmEmail {
            return "Please ensure your emails match"
        } else if Utilities.isEmailValid(email) == false {
            return "Please enter a valid email"
        }
        return nil
    }
    
    func validatePassword() -> String? {
        let password = infoTextField.text
        let confirmPassword = confirmInfoTextField.text!
        if password == "" {
            return "Please enter a password"
        } else if password != confirmPassword {
            return "Please ensure your passwords match"
        } else if Utilities.isPasswordValid(password) != true {
            return "Please ensure your password is at least 8 characters long"
        }
        return nil
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 171),
            logoImageView.widthAnchor.constraint(equalToConstant: 171),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            enterInfoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 45),
            enterInfoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -45),
            enterInfoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 30),
            
            infoTextField.heightAnchor.constraint(equalToConstant: 45),
            infoTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            infoTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            
            confirmInfoTextField.heightAnchor.constraint(equalToConstant: 45),
            confirmInfoTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            confirmInfoTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            confirmInfoTextField.topAnchor.constraint(equalTo: infoTextField.bottomAnchor, constant: 8),
            
            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: confirmInfoTextField.bottomAnchor, constant: 30)
        ])
    }
}
