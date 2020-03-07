//
//  ReauthorizeEmailViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/25/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ReauthorizeEmailViewController: UIViewController, GIDSignInDelegate {
    
    var linkingAccountType: String?
    
    var userProperty: String!
    var email: String!
    
    var logoImageView: UIImageView!
    var enterInfoLabel: UILabel!
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
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    var textViewY: CGFloat!
    var initial = true
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initial {
            textViewY = passwordTextField.frame.maxY
            initial = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var passwordTopConstraint: NSLayoutConstraint?

    func setUpElements() {
        view.backgroundColor = .white
        
        let dareLogo = UIImage(named: "RiskLogoTransparentNoText")
        logoImageView = UIImageView(image: dareLogo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)

        enterInfoLabel = UILabel()
        enterInfoLabel.text = "Enter your password"
        enterInfoLabel.textAlignment = .center
        enterInfoLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        enterInfoLabel.adjustsFontSizeToFitWidth = true
        enterInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterInfoLabel)
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "password"
        passwordTextField.isSecureTextEntry = true
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.addTarget(self, action: #selector(passwordTextFieldChanged), for: .editingChanged)
        passwordTextField.layer.zPosition = 1.0
        passwordTextField.backgroundColor = .white
        view.addSubview(passwordTextField)
        passwordTopConstraint = NSLayoutConstraint(item: passwordTextField!, attribute: .top, relatedBy: .equal, toItem: enterInfoLabel, attribute: .bottom, multiplier: 1.0, constant: 20.0)
        view.addConstraint(passwordTopConstraint!)
        
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
        
        Utilities.styleTextField(passwordTextField)
        
        bottomConstraint = NSLayoutConstraint(item: passwordTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
    }
    
    // MARK: - Actions
    
    var bottomConstraint: NSLayoutConstraint?
        
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
                }
                
                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    @objc func passwordTextFieldChanged(_ textField: UITextField) {
        if passwordTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func continueTouchUpInside() {
        guard let password = passwordTextField.text else { return }

        FirebaseUtilities.reauthenticatePasswordUser(email: email, password: password) { (error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            } else {
                let changeEmailOrPasswordVC = ChangeEmailOrPasswordViewController()
                switch self.userProperty {
                case "Email":
                    changeEmailOrPasswordVC.isEmail = true
                    self.navigationController?.show(changeEmailOrPasswordVC, sender: self)
                case "Password":
                    changeEmailOrPasswordVC.isEmail = false
                    self.navigationController?.show(changeEmailOrPasswordVC, sender: self)
                default:
                    break
                }
            }
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
    
    func validatePassword() -> String? {
        let password = passwordTextField.text
        if password == "" {
            return "Please enter a password"
        } else if Utilities.isPasswordValid(password) != true {
            return "Please ensure your password is at least 8 characters long"
        }
        return nil
    }
    
    // MARK: - Sign in to google
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            self.view.showToast(message: error!.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (result, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
                return
            }

        })
        
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

            passwordTextField.heightAnchor.constraint(equalToConstant: 45),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),

            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30)
        ])
    }
}
