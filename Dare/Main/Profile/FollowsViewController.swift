//
//  FollowingViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/9/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseFirestore
import FirebaseAuth

class FollowsViewController: ASViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource {
    
    var followersOrFollowing: String!
    let currentUseruid = Auth.auth().currentUser!.uid
    var uid: String!
        
    var profilePreviews = [ProfilePreview]()
    
    let database = Firestore.firestore()
    
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
        
        tableNode.view.allowsSelection = true
        tableNode.view.separatorStyle = .singleLine
        tableNode.view.backgroundColor = .white
        
        fetchFollows()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = followersOrFollowing
        self.navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: - Actions
    
    @objc func exitTouchUpInside() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Functions
    
    func checkIfFollowing(uidToCheckIfFollowing: String, completion: @escaping(_ isFollowing: Bool) -> ()) {
        database.collection("relationships").document("\(currentUseruid)_\(uidToCheckIfFollowing)").getDocument { (document, error) in
            if error != nil {
                print("Error checking if following user:", error!)
            }
            print("Document ID:", document?.documentID ?? "No ID boi", "| Does exist?", document!.exists)
            if document!.exists {
                return completion(true)
            } else {
                return completion(false)
            }
        }
    }
    
    func fetchFollows() {
        if followersOrFollowing == "Followers" {
            database.collection("relationships").whereField("following_uid", isEqualTo: self.uid!).getDocuments { (snapshot, error) in
                if error != nil {
                    print("Error retrieving follower IDs:", error!)
                }
                guard let unwrappedSnapshot = snapshot else { return }
                let documents = unwrappedSnapshot.documents
                
                for document in documents {
                    let documentData = document.data()
                    
                    let followeruid = documentData["follower_uid"] as? String ?? ""
                    
                    self.database.collection("users").document(followeruid).getDocument { (userSnapshot, userError) in
                        if userError != nil {
                            print("Error retrieving follower user data:", followeruid)
                        }
                        guard let unwrappedUserSnapshot = userSnapshot else { return }
                        let data = unwrappedUserSnapshot.data()
                        
                        let username = data!["username"] as? String ?? ""
                        let profilePictureURL = data!["profile_image"] as? String ?? ""
                        let fullName = data!["full_name"] as? String ?? ""
                        
                        self.checkIfFollowing(uidToCheckIfFollowing: followeruid) { (isFollowing) in
                            let profilePreview = ProfilePreview(uid: followeruid, fullName: fullName, username: username, profileImageURL: profilePictureURL, isFollowing: isFollowing)
                            if followeruid == self.currentUseruid {
                                profilePreview.isCurrentUser = true
                            }
                            self.profilePreviews.append(profilePreview)
                            self.tableNode.reloadData()
                        }
                    }
                }
            }
        } else if followersOrFollowing == "Following" {
            database.collection("relationships").whereField("follower_uid", isEqualTo: self.uid!).getDocuments { (snapshot, error) in
                if error != nil {
                    print("Error retrieving follower IDs:", error!)
                }
                guard let unwrappedSnapshot = snapshot else { return }
                let documents = unwrappedSnapshot.documents
                
                for document in documents {
                    let documentData = document.data()
                    
                    let followinguid = documentData["following_uid"] as? String ?? ""
                    
                    self.database.collection("users").document(followinguid).getDocument { (userSnapshot, userError) in
                        if userError != nil {
                            print("Error retrieving follower user data:", userError!)
                        }
                        guard let unwrappedUserSnapshot = userSnapshot else { return }
                        let data = unwrappedUserSnapshot.data()
                        
                        let username = data!["username"] as? String ?? ""
                        let profilePictureURL = data!["profile_image"] as? String ?? ""
                        let fullName = data!["full_name"] as? String ?? ""
                        
                        self.checkIfFollowing(uidToCheckIfFollowing: followinguid) { (isFollowing) in
                            let profilePreview = ProfilePreview(uid: followinguid, fullName: fullName, username: username, profileImageURL: profilePictureURL, isFollowing: isFollowing)
                            if followinguid == self.currentUseruid {
                                profilePreview.isCurrentUser = true
                            }
                            self.profilePreviews.append(profilePreview)
                            self.tableNode.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - TableNode
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = FollowsTableCellNode()
        
        let dareLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.boldSystemFont(ofSize: 20)
        ]
        
        let countLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.white,
            .font : UIFont.systemFont(ofSize: 10)
        ]
        
        cellNode.mainLabel.attributedText = NSAttributedString(string: self.profilePreviews[indexPath.row].username, attributes: dareLabelAttributes)
        cellNode.secondaryLabel.attributedText = NSAttributedString(string: String(self.profilePreviews[indexPath.row].fullName), attributes: countLabelAttributes)
        cellNode.profileImageView.url = URL(string: self.profilePreviews[indexPath.row].profileImageURL)
        cellNode.otheruid = self.profilePreviews[indexPath.row].uid
        
        cellNode.isFollowing = self.profilePreviews[indexPath.row].isFollowing
        cellNode.isCurrentUser = self.profilePreviews[indexPath.row].isCurrentUser
        
        return cellNode
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let exploreProfileVC = ExploreProfileViewController()
        exploreProfileVC.creatoruid = self.profilePreviews[indexPath.row].uid
        self.navigationController?.show(exploreProfileVC, sender: self)
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.profilePreviews.count
    }
}
