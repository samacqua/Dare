//
//  LinkEmailViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/26/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

//
//  ReauthorizeEmailViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/25/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth

class LinkEmailViewController: UIViewController {
    
    var logoImageView: UIImageView!
    var enterInfoLabel: UILabel!
    var emailTextField: UITextField!
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
    
    var textViewY: CGFloat!
    var initial = true
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initial {
            textViewY = emailTextField.frame.maxY
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
        enterInfoLabel.text = "Enter your new email"
        enterInfoLabel.textAlignment = .center
        enterInfoLabel.font = UIFont.boldSystemFont(ofSize: 33.0)
        enterInfoLabel.adjustsFontSizeToFitWidth = true
        enterInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(enterInfoLabel)
        
        emailTextField = UITextField()
        emailTextField.placeholder = "email"
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.addTarget(self, action: #selector(emailTextFieldChanged), for: .editingChanged)
        emailTextField.layer.zPosition = 1.0
        emailTextField.backgroundColor = .white
        view.addSubview(emailTextField)
        passwordTopConstraint = NSLayoutConstraint(item: emailTextField!, attribute: .top, relatedBy: .equal, toItem: enterInfoLabel, attribute: .bottom, multiplier: 1.0, constant: 20.0)
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
        
        Utilities.styleTextField(emailTextField)
        
        bottomConstraint = NSLayoutConstraint(item: emailTextField!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
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
    
    @objc func emailTextFieldChanged(_ textField: UITextField) {
        if emailTextField.text == nil {
            enableContinueButton(isEnabled: false)
        } else {
            enableContinueButton(isEnabled: true)
        }
    }
    
    @objc func continueTouchUpInside() {
        if validateEmail() != nil {
            self.view.showToast(message: validateEmail()!)
        } else {
            let linkEmailPasswordVC = LinkEmailPasswordViewController()
            linkEmailPasswordVC.email = self.emailTextField.text!
            self.navigationController?.show(linkEmailPasswordVC, sender: self)
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
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if email == "" {
            return "Please enter your email."
        } else if Utilities.isEmailValid(email) == false {
            return "Please enter a valid email"
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

            emailTextField.heightAnchor.constraint(equalToConstant: 45),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),

            continueButton.heightAnchor.constraint(equalToConstant: 45),
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 33),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            continueButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 30)
        ])
    }
}
