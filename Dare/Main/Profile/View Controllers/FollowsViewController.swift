//
//  FollowingViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/9/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class FollowsViewController: ASViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource {
    
    var followersOrFollowing: String!
    var userID: String!
        
    var profilePreviews = [ProfilePreview]()
        
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
        
        FirebaseUtilities.fetchFollows(userID: userID, followersOrFollowing: followersOrFollowing) { (profilePreviews, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            guard let profilePreviews = profilePreviews else { return }
            self.profilePreviews = profilePreviews
            self.tableNode.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = followersOrFollowing
    }
    
    // MARK: - Actions
    
    @objc func exitTouchUpInside() {
        navigationController?.popViewController(animated: true)
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
