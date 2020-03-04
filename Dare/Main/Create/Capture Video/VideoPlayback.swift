//
//  VideoPlayback.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/30/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayback: UIViewController {
    
    var exitButton: UIButton!
    var continueButton: UIButton!
    
    var player = AVPlayer()
    var playerLooper: NSObject?
    var playerLayer: AVPlayerLayer!
    var queuePlayer: AVQueuePlayer?
    var videoURL: URL!
    var videoView: UIView!
    
    var dare = Dare()
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
        
        setUpElements()
        setUpConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo()
    }
    
    func setUpElements() {
        videoView = UIView()
        videoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoView)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoView.layer.insertSublayer(playerLayer, at: 0)
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.tintColor = .white
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        view.addSubview(exitButton)
        
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        Utilities.styleFilledButton(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonPressed), for: .touchUpInside)
        view.addSubview(continueButton)
    }
    
    // MARK: - Actions
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func continueButtonPressed() {
        self.player.pause()
        let darePostVC = DarePostViewController()
        darePostVC.videoURL = videoURL
        darePostVC.dare = self.dare
        self.navigationController?.show(darePostVC, sender: self)
    }
    
    // MARK: - Functions
    
    func playVideo() {
        let playerItem = AVPlayerItem(url: videoURL!)
        self.player = AVQueuePlayer(items: [playerItem])
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLooper = AVPlayerLooper(player: self.player as! AVQueuePlayer, templateItem: playerItem)
        self.view.layer.insertSublayer(self.playerLayer!, at: 0)
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
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            continueButton.heightAnchor.constraint(equalToConstant: 35),
            continueButton.widthAnchor.constraint(equalToConstant: 90),
            continueButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }
}
