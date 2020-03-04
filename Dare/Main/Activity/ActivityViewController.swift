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
        tableNode.view.backgroundColor = .white
        
        fetchRecentActivity()
    }

    // MARK: - Functions
    
    func fetchRecentActivity() {
        
        print("Fetching recent activity")
        
        let activityRef = database.collection("users").document(uid).collection("activity")
        var queryRef: Query
        
        queryRef = activityRef.order(by: "timestamp", descending: true).limit(to: 10)
        queryRef.getDocuments { (snapshot, error) in
            if error != nil {
                print("Error retrieving recent activity: ", error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
                        
            print("Got activity documents. There are " + String(documents.count) + " documents")
            
            for document in documents {
                let documentData = document.data()
                
                print("Document data:", documentData)
                
                let timestamp = documentData["timestamp"] as! Timestamp? ?? Timestamp(date: Date(timeIntervalSince1970: 0))
                let timestampDate = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
                
                let profileData = documentData["profile"] as? [String: Any] ?? ["":""]
                let profilePictureURL = profileData["profile_picture_URL"] as? String ?? ""
                let notificationuid = profileData["uid"] as? String ?? ""
                let username = profileData["username"] as? String ?? ""
                
                let type = documentData["type"] as? String ?? ""
                
                let activity = Activity(uid: notificationuid, profilePictureURL: profilePictureURL, username: username, type: type, timestamp: timestampDate)

                if type == "like" || type == "comment" {
                    let thumbnailPictureURL = documentData["thumbnail_picture_URL"] as? String ?? "No thumbnail picture URL"
                    activity.thumbnailPictureURL = thumbnailPictureURL
                    self.activityInstances.append(activity)
                    self.tableNode.reloadData()
                } else if type == "follow" {
                    FirebaseUtilities.checkIfFollowing(followeruid: self.uid, followinguid: notificationuid) { (isFollowing, error) in
                        if error != nil {
                            self.view.showToast(message: error!.localizedDescription)
                        }
                        activity.isCurrentUserFollowing = isFollowing!
                        self.activityInstances.append(activity)
                        self.tableNode.reloadData()
                    }
                }
            }
        }
    }

    // MARK: - TableNode
    
     func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = ActivityCellNode()
        
        let usernameBoldLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.boldSystemFont(ofSize: 16)
        ]
        
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.darkGray,
            .font : UIFont.systemFont(ofSize: 16)
        ]
        
        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.lightGray,
            .font : UIFont.systemFont(ofSize: 10),
        ]
        
        cellNode.profileImageView.url = URL(string: self.activityInstances[indexPath.row].profilePictureURL)
        cellNode.otheruid = self.activityInstances[indexPath.row].uid
        let timestampText = self.activityInstances[indexPath.row].timestamp.timeAgoDisplay()
        cellNode.timestampLabel.attributedText = NSAttributedString(string: timestampText, attributes: timestampAttributes)
        
        let type = self.activityInstances[indexPath.row].type
        let usernameText = NSMutableAttributedString(string: self.activityInstances[indexPath.row].username, attributes: usernameBoldLabelAttributes)
        
        if type == "follow" {
            cellNode.type = "follow"
            let descriptionText = NSMutableAttributedString(string: " followed you", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
            cellNode.activityLabel.attributedText = usernameText
            cellNode.isFollowing = self.activityInstances[indexPath.row].isCurrentUserFollowing
        } else if type == "comment" {
            cellNode.type = "comment"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " commented '\(self.activityInstances[indexPath.row].comment!)' on your post", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
            cellNode.activityLabel.attributedText = usernameText
        } else if type == "like" {
            cellNode.type = "like"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " liked your post", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
            cellNode.activityLabel.attributedText = usernameText
        } else if type == "mention" {
            cellNode.type = "mention"
            cellNode.postThumbnailImageView.url = URL(string: self.activityInstances[indexPath.row].thumbnailPictureURL)
            let descriptionText = NSMutableAttributedString(string: " mentioned you in a comment: \(self.activityInstances[indexPath.row].comment!)", attributes: descriptionAttributes)
            usernameText.append(descriptionText)
            cellNode.activityLabel.attributedText = usernameText
        }
        return cellNode
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return activityInstances.count
    }
}
