//
//  StartViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import AVKit

class StartViewController: UIViewController {
    
    var videoPlayer : AVPlayer?
    var videoPlayerLayer : AVPlayerLayer?
    
    var logoImageView: UIImageView!
    var signUpButton: UIButton!
    var loginButton: UIButton!
    
    var initial = true
        
    // MARK: - Setup
    
    override func viewWillAppear(_ animated: Bool) {
        if initial {
            setUpVideo()
            initial = false
        } else {
            videoPlayer?.seek(to: CMTime.zero)
            videoPlayer?.play()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        setUpConstraints()
        fadeInLogo()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayer?.pause()
    }
    
    func setUpElements() {
        view.backgroundColor = .gray
        
        signUpButton = UIButton(type: .system)
        signUpButton.setTitle("Sign Up", for: .normal)
        Utilities.styleFilledButton(signUpButton)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.addTarget(self, action: #selector(signUpTouchUpInside), for: .touchUpInside)
        view.addSubview(signUpButton)
        
        loginButton = UIButton(type: .system)
        loginButton.setTitle("Login", for: .normal)
        Utilities.styleHollowButton(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(loginTouchUpInside), for: .touchUpInside)
        view.addSubview(loginButton)
        
        let dareLogo = UIImage(named: "RiskLogoTransparentJan")
        logoImageView = UIImageView(image: dareLogo)
        logoImageView.alpha = 1
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
    }
    
    // MARK: Actions
    
    @objc func loginTouchUpInside() {
        let loginVC = LoginViewController()
        self.navigationController?.show(loginVC, sender: self)
    }
    
    @objc func signUpTouchUpInside() {
        let signUpVC = SignUpViewController()
        self.navigationController?.show(signUpVC, sender: self)
    }
    
    // MARK: Functions
    
    func setUpVideo() {
        let bundlePath = Bundle.main.path(forResource: "hills", ofType: "mp4")
        guard bundlePath != nil else { return }
        let url = URL(fileURLWithPath: bundlePath!)
        let item = AVPlayerItem(url: url)
        
        videoPlayer = AVPlayer(playerItem: item)
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer!)
        videoPlayerLayer?.frame = CGRect(x: -self.view.frame.size.width * 1.7, y: 0, width: self.view.frame.size.width*4.2, height: self.view.frame.size.height)
        view.layer.insertSublayer(videoPlayerLayer!, at: 0)
        videoPlayer?.playImmediately(atRate: 1)
    }
    
    func fadeInLogo() {
        let fadeIn: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = 8
        fadeIn.isCumulative = true
        logoImageView.layer.add(fadeIn, forKey: "fadeInAnimation")
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 232),
            logoImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            signUpButton.heightAnchor.constraint(equalToConstant: 53),
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            signUpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            signUpButton.bottomAnchor.constraint(equalTo: loginButton.topAnchor, constant: -15),
            
            loginButton.heightAnchor.constraint(equalToConstant: 53),
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            loginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15)
        ])
    }
}
