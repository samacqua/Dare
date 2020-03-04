//
//  HomeViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AsyncDisplayKit

// TODO: Setup Explore Page that loads posts similar to ones user posts/interacts with
// TODO: Setup activity page
// TODO: Better home layout to fit all screen sizes
// TODO: Stylize profile header
// TODO: Cache one or a few videos so that when loaded no wait for post
// TODO: Listen to data usage and tone it down if doing too much
// TODO: Check if dare sent to database is okay with cloud functions
// TODO: Let user sign in w username
// TODO: Setup Twitter login
// TODO: Custom video cropping vc
// TODO: Apply batch updates to Dares
// TODO: Rename variables/field names to match
// TODO: Regex to validate inputs during login/sign up, and when changing user info
// TODO: Setup database rules
// TODO: Let users draw on profile
// TODO: Have fallback for post loading so that only stores some following_post_IDs in user data, using cloud functions and call to uids
// TODO: Have profile counts be listeners/life updates
// TODO: Instead of retrieving current user's info before sending data/to retrieve data, store it locally (i.e. profile picture url, username)
// TODO: Only enable button if text in texview
// TODO: Comments: enable liking/unliking and store info; insert new tablecell into top of tablenode right after post, stick comments header to top even when scrolling down, make UI better, allow to send w/ send button
// TODO: Fix Dare posting--all batch, sends post to own posts to put on HomeVC
// TODO: Create dare page
// TODO: Random dare page
// TODO: Add splash screen to each dare that says what the dare is
// TODO: Get cameraview to load before viewDidLoad
// TODO: Use Cloud Functions to update denormalized data instead of doing it on the client side
// TODO: Clean up google sign in bc its gross atm
// TODO: Cloud function to get username from given uid
// TODO: Function for attributes in activities instead of list of properties
// TODO: Implement display name as username
// TODO: Improve Password regex to not include weird characters or white spaces
// TODO: Reload data when get back to edit profile from changing data
// TODO: Implement username search

class HomeViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var flowLayout: UICollectionViewFlowLayout!
    var collectionNode: ASCollectionNode!
    
    var posts = [Post]()
    let filename = String()
    
    let database = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    let storageRef = Storage.storage().reference()
    
    var reachedEnd = false
    
    var tabBarBackgroundImage = UIImage()
    var tabBarShadowImage = UIImage()
    
    // MARK: - Initialization and Setup
    
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
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    // Hide navigation bar, set up tab bar, and fetch posts
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
        let tabBar = self.tabBarController!.tabBar
        
        tabBar.barTintColor = .black
        tabBar.isOpaque = true
        tabBar.backgroundImage = UIImage(named: "Random_Dare")
        
        let backgroundColor = UIColor(white: 0.0, alpha: 0.95)
        tabBar.backgroundImage = UIImage.from(color: backgroundColor)
        tabBar.unselectedItemTintColor = UIColor(white: 0.5, alpha: 1.0)
        tabBar.shadowImage = UIImage.from(color: backgroundColor)
    }
    
    // MARK: - CollectionNode
    
    // Give each cell node their info
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        
        let cellNode = PostCellNode()
        
        let boldLabelAttributes = Utilities.createAttributes(color: .white, fontSize: 18, bold: true, shadow: true)
        let captionAttributes = Utilities.createAttributes(color: .white, fontSize: 16, bold: false, shadow: true)
        let timestampAttributes = Utilities.createAttributes(color: .lightGray, fontSize: 14, bold: false, shadow: true)
        
        cellNode.asset = AVAsset(url: URL(string: posts[indexPath.row].pathToVideo)!)
        
        cellNode.parentViewController = self
        cellNode.postID = self.posts[indexPath.row].postID
        cellNode.creatoruid = self.posts[indexPath.row].creatoruid
        
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
        FirebaseUtilities.getPostIDs(userID: uid, collection: "following_post_IDs") { (postIDs, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            guard let postIDs = postIDs else { return }
            FirebaseUtilities.fetchPosts(postIDs: postIDs, lastPost: self.posts.last, postsToLoadInitial: 3, postsToLoad: 5) { (newPosts, error) in
                if error != nil {
                    self.view.showToast(message: error!.localizedDescription)
                }
                self.posts.append(contentsOf: newPosts!)
                
                let newPostsCount = newPosts!.count

                self.reachedEnd = newPostsCount == 0
                if !self.reachedEnd {
                    
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
}

// MARK: - Auto-scroll Extension

// Makes scrolls snap to post cells
extension HomeViewController: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let layout = self.collectionNode.collectionViewLayout as! UICollectionViewFlowLayout
        let cellHeightAndSpacing = layout.itemSize.height
        
        var offset = targetContentOffset.pointee
        let index = (offset.y / cellHeightAndSpacing)
        let roundedIndex = round(index)
        
        offset = CGPoint(x: 0, y: roundedIndex * UIScreen.main.bounds.height)
        targetContentOffset.pointee = offset
    }
}
