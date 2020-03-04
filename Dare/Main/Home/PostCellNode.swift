//
//  PostCellNode.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import AVFoundation
import AsyncDisplayKit
import FirebaseFirestore
import FirebaseAuth

class PostCellNode: ASCellNode {
    
    private var detailsTransitioningDelegate: InteractiveModalTransitioningDelegate!
    
    var dareButton = ASButtonNode()
    
    var profileImage = ASNetworkImageNode()
    var likeButton = ASButtonNode()
    var likeCountLabel = ASTextNode()
    var commentButton = ASButtonNode()
    var commentCountLabel = ASTextNode()
    var shareButton = ASButtonNode()
    
    var usernameLabel = ASTextNode()
    var timestampLabel = ASTextNode()
    var captionLabel = ASTextNode()
    
    let videoNode = ASVideoNode()
    var asset = AVAsset(url: Constants.placeholderAssetURL)
    
    var isLiked = false
    
    var dareID: String?
    var postID: String?
    var creatoruid: String?
    
    let databaseRef = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    
    var parentViewController: UIViewController? = nil
    
    let profileImageDimension = 50.0
    
    var thumbnailPictureURL: String!
        
    // MARK: - Initialization and setup
    
    override init() {
        super.init()
        self.automaticallyManagesSubnodes = true
        setUpElements()
    }
    
    override func didLoad() {
        super.didLoad()
        checkIfLiked()
//        playVideo()
    }
    
    func setUpElements() {
        self.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        
        let postElementShadow = NSShadow()
        postElementShadow.shadowBlurRadius = 5
        postElementShadow.shadowOffset = CGSize(width: 0, height: 0)
        postElementShadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
        
        let boldLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.white,
            .font : UIFont.boldSystemFont(ofSize: 18),
            .shadow : postElementShadow
        ]
        
        dareButton.setAttributedTitle(NSAttributedString(string: "Dare", attributes: boldLabelAttributes), for: .normal)
        dareButton.addTarget(self, action: #selector(dareButtonPressed), forControlEvents: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImage.view.addGestureRecognizer(tap)
        profileImage.view.isUserInteractionEnabled = true
        
        profileImage.layer.cornerRadius = CGFloat(profileImageDimension / 2.0)
        profileImage.layer.masksToBounds = true
        profileImage.layer.borderWidth = 1
        profileImage.layer.borderColor = UIColor.white.cgColor
        
        let likeImage = ASImageNodeTintColorModificationBlock(.white)(UIImage(named: "like_filled")!)
        likeButton.setImage(likeImage, for: .normal)
        likeButton.imageNode.contentMode = .scaleAspectFit
        likeButton.shadowColor = UIColor.black.cgColor
        likeButton.shadowRadius = 22.5
        likeButton.shadowOpacity = 0.3
        likeButton.layer.masksToBounds = false
        likeButton.style.preferredSize = CGSize(width: 45, height: 45)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), forControlEvents: .touchUpInside)
                
        let commentImage = ASImageNodeTintColorModificationBlock(.white)(UIImage(named: "comment_icon")!)
        commentButton.setImage(commentImage, for: .normal)
        commentButton.shadowColor = UIColor.black.cgColor
        commentButton.shadowRadius = 22.5
        commentButton.shadowOpacity = 0.5
        commentButton.layer.masksToBounds = false
        commentButton.style.preferredSize = CGSize(width: 45, height: 45)
        commentButton.addTarget(self, action: #selector(commentButtonTapped), forControlEvents: .touchUpInside)
                
        let shareImage = ASImageNodeTintColorModificationBlock(.white)(UIImage(named: "share_icon")!)
        shareButton.shadowColor = UIColor.black.cgColor
        shareButton.shadowRadius = 22.5
        shareButton.shadowOpacity = 0.5
        shareButton.layer.masksToBounds = false
        shareButton.setImage(shareImage, for: .normal)
        shareButton.style.preferredSize = CGSize(width: 45, height: 45)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), forControlEvents: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc func dareButtonPressed() {
        let darePageVC = DarePageViewController()
        darePageVC.dareID = dareID
        parentViewController?.navigationController?.show(darePageVC, sender: self)
    }
    
    @objc func profileImageTapped() {
        if creatoruid != uid {
            let exploreProfileVC = ExploreProfileViewController()
            exploreProfileVC.creatoruid = creatoruid
            parentViewController?.navigationController?.show(exploreProfileVC, sender: self)
        } else {
            let profileVC = ProfileViewController()
            parentViewController?.navigationController?.show(profileVC, sender: self)
        }
    }
    
    @objc func likeButtonTapped() {
                
        let postElementShadow = NSShadow()
        postElementShadow.shadowBlurRadius = 5
        postElementShadow.shadowOffset = CGSize(width: 0, height: 0)
        postElementShadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
        
        let boldLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.white,
            .font : UIFont.boldSystemFont(ofSize: 18),
            .shadow : postElementShadow
        ]
        
        var currentNumberOfLikes = Int(likeCountLabel.attributedText!.string) ?? 0
        
        if isLiked == true {
            let likeImage = ASImageNodeTintColorModificationBlock(.white)(UIImage(named: "like_filled")!)
            currentNumberOfLikes += -1
            likeButton.setImage(likeImage, for: .normal)
            likeCountLabel.attributedText = NSAttributedString(string: String(currentNumberOfLikes), attributes: boldLabelAttributes)
            
            guard let unwrappedPostID = postID else { return }
            guard let unwrappedCreatorID = creatoruid else { return }
            FirebaseUtilities.unlikePost(postID: unwrappedPostID, creatoruid: unwrappedCreatorID) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            }
            isLiked = false
        } else {
            let likeImage = ASImageNodeTintColorModificationBlock(.red)(UIImage(named: "like_filled")!)
            currentNumberOfLikes += 1
            likeButton.setImage(likeImage, for: .normal)
            likeCountLabel.attributedText = NSAttributedString(string: String(currentNumberOfLikes), attributes: boldLabelAttributes)
            
            guard let unwrappedPostID = postID else { return }
                    
            FirebaseUtilities.likePost(postID: unwrappedPostID, creatoruid: creatoruid!, thumbnailPictureURL: thumbnailPictureURL) { (error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
            }
            isLiked = true
        }
    }
    
    @objc func commentButtonTapped() {
        let commentVC = CommentViewController()
        detailsTransitioningDelegate = InteractiveModalTransitioningDelegate(from: parentViewController!, to: commentVC)
        commentVC.modalPresentationStyle = .custom
        commentVC.transitioningDelegate = detailsTransitioningDelegate
        commentVC.postID = postID
        parentViewController?.present(commentVC, animated: true, completion: nil)
    }
    
    @objc func shareButtonTapped() {
        self.view.showToast(message: "Share button tapped")
        print("share tapped")
    }
    
    // MARK: - Functions
    
    func checkIfLiked() {
        
        guard let unwrappedPostID = postID else { return }
        
        FirebaseUtilities.checkIfLiked(postID: unwrappedPostID) { (isLiked, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
                return
            }
            self.isLiked = isLiked!
            if isLiked! {
                let likeImage = ASImageNodeTintColorModificationBlock(.red)(UIImage(named: "like_filled")!)
                self.likeButton.setImage(likeImage, for: .normal)
            }
        }
    }
    
    func playVideo() {
        videoNode.asset = asset
        videoNode.shouldAutoplay = true
        videoNode.shouldAutorepeat = true
        videoNode.muted = false
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        videoNode.style.minHeight = ASDimensionMakeWithFraction(1)
        videoNode.style.minWidth = ASDimensionMakeWithFraction(1)
        videoNode.gravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        
        profileImage.style.preferredSize = CGSize(width: profileImageDimension, height: profileImageDimension)
        
        let usernameTimestampSpec = ASStackLayoutSpec.horizontal()
        usernameTimestampSpec.spacing = 8
        usernameTimestampSpec.alignItems = .baselineFirst
        usernameTimestampSpec.children = [usernameLabel, timestampLabel]
        
        let postInfoSpec = ASStackLayoutSpec.vertical()
        postInfoSpec.justifyContent = .start
        postInfoSpec.spacing = 8
        postInfoSpec.style.flexGrow = 1
        postInfoSpec.children = [usernameTimestampSpec, captionLabel]
        
        let likeStackSpec = ASStackLayoutSpec(direction: .vertical, spacing: 7, justifyContent: .end, alignItems: .center, children: [likeButton, likeCountLabel])
        let commentStackSpec = ASStackLayoutSpec(direction: .vertical, spacing: 5, justifyContent: .end, alignItems: .center, children: [commentButton, commentCountLabel])
        let actionStackSpec = ASStackLayoutSpec(direction: .vertical, spacing: 24, justifyContent: .end, alignItems: .center, children: [profileImage, likeStackSpec, commentStackSpec, shareButton])
        
        let horizontalStackSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .end, alignItems: .baselineLast, children: [postInfoSpec, actionStackSpec])
        
        let dareRelativeSpec = ASRelativeLayoutSpec(horizontalPosition: .center, verticalPosition: .start, sizingOption: [], child: dareButton)
        dareRelativeSpec.style.flexGrow = 1.0
        
        let finalStackSpec = ASStackLayoutSpec()
        finalStackSpec.direction = .vertical
        finalStackSpec.children = [dareRelativeSpec, horizontalStackSpec]
        finalStackSpec.spacing = 0
        
        let insetSpec = ASInsetLayoutSpec(insets:UIEdgeInsets(top: 12, left: 10, bottom: 60, right: 10), child: finalStackSpec)
        
        return ASOverlayLayoutSpec(child: videoNode, overlay: insetSpec)
    }
}
