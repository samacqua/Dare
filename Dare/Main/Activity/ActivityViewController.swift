//
//  ActivityViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseFirestore
import FirebaseAuth

final class ActivityViewController: ASViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate {

    let database = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    
    var activityInstances = [Activity]()

    var tableNode: ASTableNode {
        return node as! ASTableNode
    }
    
    // MARK: - Initalization and Setup
    
    init() {
        super.init(node: ASTableNode())
        
        tableNode.delegate = self
        tableNode.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activity"
        self.tabBarItem.title = nil
        
        tableNode.view.allowsSelection = true
        tableNode.view.separatorStyle = .singleLine
        tableNode.view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        FirebaseUtilities.fetchRecentActivity { (activities, error) in  // TODO: Update based on scroll
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            self.activityInstances = activities!
            self.tableNode.reloadData()
        }
    }
    
    // MARK: - TableNode
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = ActivityCellNode()
        
        cellNode.parentVC = self
        
        let usernameBoldLabelAttributes = Utilities.createAttributes(color: .black, fontSize: 16, bold: true, shadow: false)
        let descriptionAttributes = Utilities.createAttributes(color: .darkGray, fontSize: 16, bold: false, shadow: false)
        let timestampAttributes = Utilities.createAttributes(color: .lightGray, fontSize: 10, bold: false, shadow: false)
        
        cellNode.profileImageView.url = URL(string: self.activityInstances[indexPath.row].profilePictureURL)
        cellNode.otheruid = self.activityInstances[indexPath.row].uid
        let timestampText = self.activityInstances[indexPath.row].timestamp.timeAgoDisplay()
        cellNode.timestampLabel.attributedText = NSAttributedString(string: timestampText, attributes: timestampAttributes)
        
        let type = self.activityInstances[indexPath.row].type
        let usernameText = NSMutableAttributedString(string: self.activityInstances[indexPath.row].username, attributes: usernameBoldLabelAttributes)
        
        switch type {
        case "follow":
            cellNode.type = "follow"
            let descriptionText = NSMutableAttributedString(string: " followed you", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
            cellNode.isFollowing = self.activityInstances[indexPath.row].isCurrentUserFollowing
        case "comment":     // TODO: add cloud function
            cellNode.type = "comment"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " commented '\(self.activityInstances[indexPath.row].comment!)' on your post", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
        case "like":
            cellNode.type = "like"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " liked your post", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
        case "mention":     // TODO: add cloud function
            cellNode.type = "mention"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " mentioned you in a comment: \(self.activityInstances[indexPath.row].comment!)", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
        default:
            break
        }
        cellNode.activityLabel.attributedText = usernameText
        return cellNode
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let activity = self.activityInstances[indexPath.row]
        let type = activity.type
        
        switch type {
        case "follow":
            let exploreProfileVC = ExploreProfileViewController()
            exploreProfileVC.creatoruid = activity.uid
            self.navigationController?.show(exploreProfileVC, sender: self)
        default: // TODO: Rename ProfilePostSelectedViewController
            let postSelectedVC = ProfilePostSelectedViewController()    // A bit awkward because only one post, but prefer this awkwardness over having an entire VC for basically the same functionality
            postSelectedVC.postIDs = [activity.postID]
            self.navigationController?.show(postSelectedVC, sender: self)
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return activityInstances.count
    }
}
