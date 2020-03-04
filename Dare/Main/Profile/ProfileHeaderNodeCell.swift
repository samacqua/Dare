//
//  ProfileHeaderNodeCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/10/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileHeaderNodeCell: ASCellNode {
    
    var parentVC: UIViewController!
    
    var nameLabel = ASTextNode()
    var bioLabel = ASTextNode()
    var followerButton = ASButtonNode()
    var followingButton = ASButtonNode()
    var dareCountLabel = ASTextNode()
        
    var topDaresCollectionNode: ASCollectionNode!
    var topDaresPostPreviews = [PostPreview]()
    
    var segmentedView = UISegmentedControl(items: ["Dares completed", "Dares created"])
    lazy var segmentedNode: ASDisplayNode = {
        return ASDisplayNode(viewBlock: { () -> UIView in
            self.segmentedView.selectedSegmentIndex = 0
            self.segmentedView.removeBorder()
            self.segmentedView.addUnderlineForSelectedSegment()
            self.segmentedView.addTarget(self, action: #selector(self.segmentedControlChanged), for: .valueChanged)
            
            return self.segmentedView
        })
    }()

    var profileImage = ASNetworkImageNode()
    
    var editProfileButton = ASButtonNode()
    var likedPostsButton = ASButtonNode()
    
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    
    // MARK: - Initialization and setup
    
    override init() {
        let flowLayout = UICollectionViewFlowLayout()
        topDaresCollectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        
        super.init()
        
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.scrollDirection = .horizontal
        self.automaticallyManagesSubnodes = true
        
        getUserTopPostPreviews()
        
        setUpElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        topDaresCollectionNode.delegate = self
        topDaresCollectionNode.dataSource = self
        
        topDaresCollectionNode.view.backgroundColor = .white
        topDaresCollectionNode.allowsSelection = true
        topDaresCollectionNode.showsHorizontalScrollIndicator = false
        topDaresCollectionNode.alwaysBounceHorizontal = true
        self.view.addSubnode(topDaresCollectionNode)
        
        profileImage.defaultImage = UIImage(named: "profile_selected")
        profileImage.layer.backgroundColor = UIColor.lightGray.cgColor
        profileImage.layer.cornerRadius = 50
        profileImage.clipsToBounds = true
        
        let editProfileAttributes = Utilities.createAttributes(color: .white, fontSize: 18, bold: true, shadow: false)
        let editProfileText = NSAttributedString(string: "Edit profile", attributes: editProfileAttributes)
        editProfileButton.backgroundColor = .orange
        editProfileButton.cornerRadius = 5.0
        editProfileButton.setAttributedTitle(editProfileText, for: .normal)
        
        let likedPostsAttributes = Utilities.createAttributes(color: .orange, fontSize: 18, bold: true, shadow: false)
        let likedPostsText = NSAttributedString(string: "Liked posts", attributes: likedPostsAttributes)
        likedPostsButton.borderColor = UIColor.orange.cgColor
        likedPostsButton.borderWidth = 3.0
        likedPostsButton.cornerRadius = 5.0
        likedPostsButton.setAttributedTitle(likedPostsText, for: .normal)
    }
    
    @objc func segmentedControlChanged() {
        segmentedView.changeUnderlinePosition()
    }
    
    func getUserTopPostPreviews() {
        FirebaseUtilities.getUserPostPreviews(profileuid: Auth.auth().currentUser!.uid) { (postPreviews, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            self.topDaresPostPreviews = postPreviews!
            self.topDaresCollectionNode.reloadData()
        }
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let screenWidth = UIScreen.main.bounds.width
        profileImage.style.preferredSize.height = 100.0
        profileImage.style.preferredSize.width = 100.0
        
        editProfileButton.style.preferredSize = CGSize(width: 150.0, height: 35.0)
        likedPostsButton.style.preferredSize = CGSize(width: 150.0, height: 35.0)
        
        segmentedNode.style.preferredSize = CGSize(width: screenWidth - 18, height: 30.0)
        segmentedNode.style.alignSelf = .center
        
        let followerFollowingStack = ASStackLayoutSpec.horizontal()
        followerFollowingStack.children = [followerButton, followingButton]
        followerFollowingStack.spacing = 6
        
        bioLabel.style.maxWidth = ASDimensionMake(screenWidth - 15 - 15 - 100 - 4)
        let topVertStack = ASStackLayoutSpec.vertical()
        topVertStack.children = [nameLabel, bioLabel, followerFollowingStack, dareCountLabel]
        topVertStack.spacing = 6.0
        topVertStack.style.flexGrow = 1.0
        dareCountLabel.style.spacingBefore = -4.0
        
        let topHorStack = ASStackLayoutSpec.horizontal()
        topHorStack.children = [topVertStack, profileImage]
        topHorStack.justifyContent = .end
        topHorStack.alignItems = .stretch
        topHorStack.style.flexGrow = 1.0
        
        let editLikedPostsStack = ASStackLayoutSpec(direction: .horizontal, spacing: 8, justifyContent: .center, alignItems: .center, children: [editProfileButton, likedPostsButton])

        topDaresCollectionNode.style.preferredSize = CGSize(width: screenWidth - 20, height: 60)
        
        let completeStack = ASStackLayoutSpec.vertical()
        completeStack.children = [topHorStack, editLikedPostsStack, topDaresCollectionNode, segmentedNode]
        completeStack.spacing = 12.0

        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 15, left: 15, bottom: -1, right: 15), child: completeStack)
    }
}

extension ProfileHeaderNodeCell: ASCollectionDataSource, ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let cell = TopDaresNodeCell()
        if indexPath.row == 0 {
            return cell
        }
        cell.thumbnailImage.url = URL(string: topDaresPostPreviews[indexPath.row - 1].thumbnailImageURL)
        return cell
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return topDaresPostPreviews.count + 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        let minSize = CGSize(width: 60, height: 60)
        let maxSize = CGSize(width: 60, height: 60)
        return(ASSizeRange(min: minSize, max: maxSize))
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.parentVC.self.tabBarController?.selectedIndex = 2
        }
        let postSelectedVC = ProfilePostSelectedViewController()
        postSelectedVC.postPreviews = topDaresPostPreviews
        postSelectedVC.postIndexPathRow = indexPath.row - 1
        parentVC.navigationController?.show(postSelectedVC, sender: self)
        
    }
}
