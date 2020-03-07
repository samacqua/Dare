//
//  LoginViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

import FBSDKLoginKit
import FirebaseAuth
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInDelegate {
    
    var exitButton: UIButton!
    var faqButton: UIButton!
    var logoImageView: UIImageView!
    var mainTitleLabel: UILabel!
    var moreInfoLabel: UILabel!
    var emailOrPhoneButton: UIButton!
    var emailOrPhoneImageView: UIImageView!
    var facebookButton: UIButton!
    var facebookImageView: UIImageView!
    var googleButton: UIButton!
    var googleImageView: UIImageView!
    var signUpButton: UIButton!
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        setUpConstraints()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
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
        
        emailOrPhoneButton = UIButton(type: .system)
        emailOrPhoneButton.setTitle("Use email or phone", for: .normal)
        emailOrPhoneButton.translatesAutoresizingMaskIntoConstraints = false
        emailOrPhoneButton.addTarget(self, action: #selector(emailPhoneTouchUpInside), for: .touchUpInside)
        view.addSubview(emailOrPhoneButton)
        
        let emailOrPhoneImage = UIImage(named: "email_phone_circle")
        emailOrPhoneImageView = UIImageView(image: emailOrPhoneImage)
        emailOrPhoneImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailOrPhoneImageView)
        
        facebookButton = UIButton(type: .system)
        facebookButton.setTitle("Continue with Facebook", for: .normal)
        facebookButton.translatesAutoresizingMaskIntoConstraints = false
        facebookButton.addTarget(self, action: #selector(facebookTouchUpInside), for: .touchUpInside)
        view.addSubview(facebookButton)
        
        let facebookImage = UIImage(named: "facebook_circle")
        facebookImageView = UIImageView(image: facebookImage)
        facebookImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(facebookImageView)
        
        googleButton = UIButton(type: .system)
        googleButton.setTitle("Continue with Google", for: .normal)
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.addTarget(self, action: #selector(googleTouchUpInside), for: .touchUpInside)
        view.addSubview(googleButton)
        
        let googleImage = UIImage(named: "google_circle")
        googleImageView = UIImageView(image: googleImage)
        googleImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(googleImageView)
        
        signUpButton = UIButton()
        signUpButton.setTitle("Don't have an account? Sign up", for: .normal)
        signUpButton.setTitleColor(.orange, for: .normal)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.addTarget(self, action: #selector(signUpButtonTouchUpInside), for: .touchUpInside)
        view.addSubview(signUpButton)
        
        Utilities.styleHollowButtonColored(emailOrPhoneButton)
        Utilities.styleHollowButtonColored(facebookButton)
        Utilities.styleHollowButtonColored(googleButton)
    }
    
    // MARK: - Actions
    
    @objc func faqButtonTouchUpInside() {
        print("FAQ Pressed")
    }
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func emailPhoneTouchUpInside() {
        let emailPhoneSignInVC = EmailPhoneLoginViewController()
        self.navigationController?.show(emailPhoneSignInVC, sender: self)
    }
    
    @objc func facebookTouchUpInside() {
        FirebaseUtilities.handleFacebookAuthentication(viewController: self) { (error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            let homeVC = MainTabBarController()
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }
    }
    
    @objc func googleTouchUpInside() {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    @objc func signUpButtonTouchUpInside() {
        let signUpVC = SignUpViewController()
        self.navigationController?.show(signUpVC, sender: self)
    }
    
    // MARK: - Sign in with google
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            self.view.showToast(message: error!.localizedDescription)
            return
        }
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        FirebaseUtilities.handleGoogleAuthentication(credential: credential, user: user) { (error2) in
            if error2 != nil {
                self.view.showToast(message: error2!.localizedDescription)
            }
            let homeVC = MainTabBarController()
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
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
            
            logoImageView.heightAnchor.constraint(equalToConstant: 130),
            logoImageView.widthAnchor.constraint(equalToConstant: 130),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            mainTitleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            mainTitleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 79),
            mainTitleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -79),
            
            moreInfoLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 16),
            moreInfoLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            moreInfoLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
            
            emailOrPhoneButton.heightAnchor.constraint(equalToConstant: 50),
            emailOrPhoneButton.topAnchor.constraint(equalTo: moreInfoLabel.bottomAnchor, constant: 38),
            emailOrPhoneButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            emailOrPhoneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            emailOrPhoneImageView.heightAnchor.constraint(equalToConstant: 40),
            emailOrPhoneImageView.widthAnchor.constraint(equalToConstant: 40),
            emailOrPhoneImageView.centerYAnchor.constraint(equalTo: emailOrPhoneButton.centerYAnchor),
            emailOrPhoneImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            
            facebookButton.heightAnchor.constraint(equalToConstant: 50),
            facebookButton.topAnchor.constraint(equalTo: emailOrPhoneButton.bottomAnchor, constant: 24),
            facebookButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            facebookButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            facebookImageView.heightAnchor.constraint(equalToConstant: 40),
            facebookImageView.widthAnchor.constraint(equalToConstant: 40),
            facebookImageView.centerYAnchor.constraint(equalTo: facebookButton.centerYAnchor),
            facebookImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            
            googleButton.heightAnchor.constraint(equalToConstant: 50),
            googleButton.topAnchor.constraint(equalTo: facebookButton.bottomAnchor, constant: 24),
            googleButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            googleButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            googleImageView.heightAnchor.constraint(equalToConstant: 40),
            googleImageView.widthAnchor.constraint(equalToConstant: 40),
            googleImageView.centerYAnchor.constraint(equalTo: googleButton.centerYAnchor),
            googleImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            
            signUpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -29),
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            signUpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
}
