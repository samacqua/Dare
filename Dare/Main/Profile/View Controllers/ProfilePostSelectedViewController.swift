//
//  ProfilePostSelectedViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class ProfilePostSelectedViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var flowLayout: UICollectionViewFlowLayout!
    var collectionNode: ASCollectionNode!
    
    var postIDs = [""]
    var posts = [Post]()
    var postIndexPathRow = 0
    
    var reachedEnd = false
    
    override var prefersStatusBarHidden: Bool { true }
    
    // MARK: Initialization and Setup
    
    // Setup collectionNode layout
    init() {
        flowLayout = UICollectionViewFlowLayout()
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        
        super.init(node: collectionNode)
        
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize.height = self.view.bounds.height
        flowLayout.itemSize.width = self.view.bounds.width
    }
    
    // Required initializer
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Set up collectionNode delegate/datasource and view properties
    override func viewDidLoad() {
        super.viewDidLoad()
                
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.view.allowsSelection = false
        collectionNode.view.backgroundColor = Constants.realDarkGray
        collectionNode.view.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionNode.showsVerticalScrollIndicator = false
        collectionNode.leadingScreensForBatching = 2.0
    }
        
    // Hide navigation bar, set up tab bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        let tabBar = self.tabBarController!.tabBar
        
        tabBar.barTintColor = .clear
        let backgroundColor = UIColor(white: 0.0, alpha: 0.10)
        tabBar.backgroundImage = UIImage.from(color: backgroundColor)
        tabBar.unselectedItemTintColor = .white
        tabBar.shadowImage = UIImage.from(color: UIColor(white: 1.0, alpha: 0.6))
        
    }
    
    // Format tab bar for other views
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        guard let tabBar = self.tabBarController?.tabBar else { return }

        tabBar.barTintColor = .black
        tabBar.isOpaque = true
        tabBar.backgroundImage = UIImage(named: "Random_Dare")

        let backgroundColor = UIColor(white: 0.0, alpha: 0.95)
        tabBar.backgroundImage = UIImage.from(color: backgroundColor)
        tabBar.unselectedItemTintColor = UIColor(white: 0.5, alpha: 1.0)
        tabBar.shadowImage = UIImage.from(color: backgroundColor)
    }
    
    // TODO: ScrollToItem only working in viewDidAppear, but choppy and not quite scrolling to right position.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.collectionNode.scrollToItem(at: IndexPath(row: self.postIndexPathRow, section: 0), at: .centeredVertically, animated: false)
    }
    
    // MARK: CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        
        let cellNode = PostCellNode()
        
        cellNode.asset = AVAsset(url: URL(string: posts[indexPath.row].pathToVideo)!)

        cellNode.parentViewController = self
        cellNode.postID = self.posts[indexPath.row].postID
        cellNode.creatoruid = self.posts[indexPath.row].creatoruid
        
        let boldLabelAttributes = Utilities.createAttributes(color: .white, font: .boldSystemFont(ofSize: 18), shadow: true)
        let captionAttributes = Utilities.createAttributes(color: .white, font: .systemFont(ofSize: 16), shadow: true)
        let timestampAttributes = Utilities.createAttributes(color: .lightGray, font: .systemFont(ofSize: 14), shadow: true)
        
        cellNode.profileImage.url = URL(string: self.posts[indexPath.row].pathToProfileImage)
        cellNode.commentCountLabel.attributedText = NSAttributedString(string: String(self.posts[indexPath.row].numberOfComments), attributes: boldLabelAttributes)
        cellNode.likeCountLabel.attributedText = NSAttributedString(string: String(self.posts[indexPath.row].numberOfLikes), attributes: boldLabelAttributes)
        
        let usernameText = "@\(self.posts[indexPath.row].creatorUsername)"
        cellNode.usernameLabel.attributedText = NSAttributedString(string: usernameText, attributes: boldLabelAttributes)
        let timestampText = self.posts[indexPath.row].timestamp.timeAgoDisplay()
        cellNode.timestampLabel.attributedText = NSAttributedString(string: timestampText, attributes: timestampAttributes)
        cellNode.captionLabel.attributedText = NSAttributedString(string: self.posts[indexPath.row].caption, attributes: captionAttributes)
        
        let dareButtonTitleString = NSAttributedString(string: self.posts[indexPath.row].dareFullName, attributes: boldLabelAttributes)
        cellNode.dareButton.setAttributedTitle(dareButtonTitleString, for: .normal)
        cellNode.dareID = self.posts[indexPath.row].dareID
        
        cellNode.thumbnailPictureURL = self.posts[indexPath.row].pathToThumbnail
        
        return cellNode
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    // MARK: - Texture Batch Fetch
    
    // If not at last post, fetch more
    func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        if !self.reachedEnd {
            return true
        }
        return false
    }
    
    // Load new posts if hasn't reached end, checks if reached end
    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        FirebaseUtilities.fetchPosts(postIDs: postIDs, lastPost: self.posts.last, postsToLoadInitial: 3, postsToLoad: 5) { (fetchedPosts, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            guard let newPosts = fetchedPosts else { return }
            self.posts.append(contentsOf: newPosts)
            
            self.reachedEnd = newPosts.count == 0
            if !self.reachedEnd {
                let newPostsCount = newPosts.count
                
                if self.posts.count - newPostsCount > 0 {
                    let indexRange = (self.posts.count - newPostsCount..<self.posts.count)
                    let indexPaths = indexRange.map { IndexPath(row: $0, section: 0) }
                    collectionNode.insertItems(at: indexPaths)
                    self.collectionNode.reloadItems(at: indexPaths)
                    context.completeBatchFetching(true)
                } else {
                    self.collectionNode.reloadData()
                    context.completeBatchFetching(true)
                }
            } else {
                context.completeBatchFetching(true)
            }
        }
    }
}

// MARK: Scroll-snap Extension

// Makes scrolls snap to post cells
extension ProfilePostSelectedViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let layout = self.collectionNode.collectionViewLayout as! UICollectionViewFlowLayout
        let cellHeightAndSpacing = layout.itemSize.height + layout.minimumInteritemSpacing
        
        var offset = targetContentOffset.pointee
        let index = (offset.y + scrollView.contentInset.top) / cellHeightAndSpacing
        let roundedIndex = round(index)
        
        offset = CGPoint(x: -scrollView.contentInset.right, y: roundedIndex * UIScreen.main.bounds.height - scrollView.contentInset.top)
        targetContentOffset.pointee = offset
    }
}

