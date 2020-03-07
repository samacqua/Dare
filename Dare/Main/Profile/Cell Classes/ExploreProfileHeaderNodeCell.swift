//
//  ExploreProfileHeaderNodeCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/29/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class ExploreProfileHeaderNodeCell: ASCellNode {
    
    var parentVC: UIViewController!
    var creatoruid: String!
    var isFollowing = false
    var followerCount = 0
    
    var profileImage = ASNetworkImageNode()
    
    var nameLabel = ASTextNode()
    var dareCountLabel = ASTextNode()
    var followingButton = ASButtonNode()
    var followerButton = ASButtonNode()
    
    var followButton = ASButtonNode()
    var bioLabel = ASTextNode()
    
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
    
    let followAttributes = Utilities.createAttributes(color: .white, font: .boldSystemFont(ofSize: 18), shadow: false)
    
    // MARK: - Initialization and setup
    
    override init() {
        let flowLayout = UICollectionViewFlowLayout()
        topDaresCollectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        
        super.init()
                
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.scrollDirection = .horizontal
        self.automaticallyManagesSubnodes = true
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
        profileImage.layer.cornerRadius = 50.0
        profileImage.clipsToBounds = true
        
        followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
        followButton.addTarget(self, action: #selector(followButtonTouchUpInside), forControlEvents: .touchUpInside)
        followButton.cornerRoundingType = .defaultSlowCALayer
        followButton.cornerRadius = 5.0
    }
    
    // MARK: - Actions
    
    @objc func segmentedControlChanged() {
        segmentedView.changeUnderlinePosition()
    }
    
    @objc func followButtonTouchUpInside() {        
        let followCount = Utilities.createAttributes(color: .black, font: .boldSystemFont(ofSize: 14), shadow: false)
        let followLabel = Utilities.createAttributes(color: .black, font: .systemFont(ofSize: 14), shadow: false)
        
        if !isFollowing {
            self.isFollowing = true
            let followingAttributes = Utilities.createAttributes(color: .orange, font: .boldSystemFont(ofSize: 18), shadow: false)
            
            followButton.setAttributedTitle(NSAttributedString(string: "Following", attributes: followingAttributes), for: .normal)
            followButton.backgroundColor = .white
            followButton.borderWidth = 3.0
            followButton.borderColor = UIColor.orange.cgColor
            
            followerCount += 1
        } else {
            self.isFollowing = false
            followButton.setAttributedTitle(NSAttributedString(string: "Follow", attributes: followAttributes), for: .normal)
            followButton.borderWidth = 0.0
            followButton.backgroundColor = .orange
            
            followerCount -= 1
        }
        let followerButtonString = NSMutableAttributedString(string: String(followerCount), attributes: followCount)
        let followersString = NSMutableAttributedString(string: " followers", attributes: followLabel)
        followerButtonString.append(followersString)
        
        followerButton.setAttributedTitle(followerButtonString, for: .normal)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let screenWidth = UIScreen.main.bounds.width
        profileImage.style.preferredSize.height = 100.0
        profileImage.style.preferredSize.width = 100.0
        
        followButton.style.preferredSize = CGSize(width: 200, height: 40)
        
        topDaresCollectionNode.style.preferredSize = CGSize(width: UIScreen.main.bounds.width - 20, height: 60)

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
        
        let completeStack = ASStackLayoutSpec.vertical()
        completeStack.children = [topHorStack, followButton, topDaresCollectionNode, segmentedNode]
        completeStack.spacing = 12.0

        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 15, left: 15, bottom: -1, right: 15), child: completeStack)
    }
}

extension ExploreProfileHeaderNodeCell: ASCollectionDataSource, ASCollectionDelegate {
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
        var postIDs = [""]
        for post in topDaresPostPreviews {
            postIDs.append(post.postID)
        }
        postSelectedVC.postIDs = postIDs
        postSelectedVC.postIndexPathRow = indexPath.row - 1
        parentVC.navigationController?.show(postSelectedVC, sender: self)
        
    }
}

