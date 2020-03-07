//
//  DarePostViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

class DarePostViewController: UIViewController, UITextViewDelegate {
    
    var exitButton: UIButton!
    var descriptionTextView: UITextView!
    var videoView: UIView!
    var divider: UIView!
    var draftsButton: UIButton!
    var shareButton: UIButton!
    
    var player = AVPlayer()
    var playerLooper: NSObject?
    var playerLayer:AVPlayerLayer!
    var queuePlayer: AVQueuePlayer?
    var videoURL: URL?
    let filename = NSUUID().uuidString
    
    var dare = Dare()
    var dareTitleButton: UIButton!
    
    let uid = Auth.auth().currentUser!.uid
    let database = Firestore.firestore()
    let postPath = Firestore.firestore().collection("posts").document()
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        setUpConstraints()
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setUpElements() {
        self.view.backgroundColor = .white
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.tintColor = .black
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        view.addSubview(exitButton)
        
        descriptionTextView = UITextView()
        descriptionTextView.text = "Description"
        descriptionTextView.font = UIFont.systemFont(ofSize: 18)
        descriptionTextView.textColor = .gray
        descriptionTextView.delegate = self
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionTextView)
        
        videoView = UIView()
        videoView.backgroundColor = .gray
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        
        divider = UIView()
        divider.backgroundColor = .lightGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(divider)
        
        let dareLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.systemFont(ofSize: 20)
        ]
        
        dareTitleButton = UIButton()
        let dareTitleString = NSAttributedString(string: "Dare: \(dare.dareNameFull ?? "")", attributes:dareLabelAttributes)
        dareTitleButton.setAttributedTitle(dareTitleString, for: .normal)
        dareTitleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dareTitleButton)
        
        draftsButton = UIButton()
        draftsButton.setTitle("Save as draft", for: .normal)
        Utilities.styleHollowButtonColored(draftsButton)
        draftsButton.setTitleColor(.orange, for: .normal)
        draftsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(draftsButton)
        
        shareButton = UIButton()
        shareButton.setTitle("Share", for: .normal)
        Utilities.styleFilledButton(shareButton)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        view.addSubview(shareButton)
    }
    
    // MARK: - Actions
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func shareButtonTapped() {
        FirebaseUtilities.sendPostToFirestore(videoURL: videoURL!, caption: descriptionTextView.text, dare: dare, postPath: postPath) { (uploadTask, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            let homeVC = MainTabBarController()
            homeVC.uploadTask = uploadTask
            homeVC.modalPresentationStyle = .fullScreen
            self.present(homeVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Functions
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Description" {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func playVideo() {
        let playerItem = AVPlayerItem(url: videoURL!)
        self.player = AVQueuePlayer(items: [playerItem])
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLooper = AVPlayerLooper(player: self.player as! AVQueuePlayer, templateItem: playerItem)
        self.view.layer.addSublayer(self.playerLayer!)
        self.playerLayer?.frame = videoView.frame
        self.playerLayer?.videoGravity = .resizeAspectFill
        self.player.play()
    }
    
    // MARK: - Layout
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            exitButton.heightAnchor.constraint(equalToConstant: 33),
            exitButton.widthAnchor.constraint(equalToConstant: 33),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            
            descriptionTextView.topAnchor.constraint(equalTo: exitButton.bottomAnchor, constant: 8),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: -8),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 196),
            
            videoView.heightAnchor.constraint(equalToConstant: 196),
            videoView.widthAnchor.constraint(equalToConstant: 133),
            videoView.topAnchor.constraint(equalTo: descriptionTextView.topAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            videoView.leadingAnchor.constraint(equalTo: descriptionTextView.trailingAnchor, constant: 8),
            
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 18),
            divider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            divider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            
            dareTitleButton.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 10),
            dareTitleButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            
            draftsButton.heightAnchor.constraint(equalToConstant: 60),
            draftsButton.widthAnchor.constraint(equalToConstant: 374),
            draftsButton.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -15),
            draftsButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            draftsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            shareButton.heightAnchor.constraint(equalToConstant: 60),
            shareButton.widthAnchor.constraint(equalToConstant: 374),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            shareButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            shareButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
    }
}
