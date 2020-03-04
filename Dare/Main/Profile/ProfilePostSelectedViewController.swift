//
//  ProfilePostSelectedViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AsyncDisplayKit

class ProfilePostSelectedViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var flowLayout: UICollectionViewFlowLayout!
    var collectionNode: ASCollectionNode!
    
    var postPreviews = [PostPreview]()
    var posts = [Post]()
    var postIndexPathRow = 0
    
    let database = Firestore.firestore()
    let storageRef = Storage.storage().reference()
    let uid = Auth.auth().currentUser!.uid
    
    var reachedEnd = false
    
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
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
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
    
    // MARK: Functions
    
    // Fetches postIDs from given class postPreviews
    func fetchPostIDs(completion: @escaping(_ postIDs:[String]) -> ()) {
        var postIDs = [String]()
        for post in postPreviews {
            postIDs.append(post.postID)
        }
        return completion(postIDs)
    }
    
    // given a set of postIDs, it returns 3 more posts on the first call, then 5 more posts.
    // TODO: Won't scroll to post if is not one of the first three
    func fetchPosts(postIDs: [String], completion: @escaping(_ posts:[Post]) -> ()) {
        
        let postsRef = self.database.collection("posts").whereField("post_ID", in: postIDs)
        let lastPost = self.posts.last
        var queryRef: Query
        
        if lastPost == nil {
            queryRef = postsRef.order(by: "timestamp", descending: true).limit(to: 5)
        } else {
            let lastTimestamp = lastPost!.timestamp
            queryRef = postsRef.order(by: "timestamp", descending: true).start(after: [lastTimestamp]).limit(to: 5)
        }

        queryRef.getDocuments { (snapshot, error) in
            if error != nil {
                print("Error listening for new posts:", error!)
            }
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var tempPosts = [Post]()
            
            for document in documents {
                let documentData = document.data()
                
                let postID = documentData["post_ID"] as? String ?? ""
                let dareID = documentData["dare_ID"] as? String ?? ""
                
                let timestamp = documentData["timestamp"] as! Timestamp? ?? Timestamp(date: Date(timeIntervalSince1970: 0))
                let timestampDate = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
                
                let pathToVideo = documentData["video_URL"] as? String ?? ""
                
                let caption = documentData["caption"] as? String ?? ""
                let dareFullName = documentData["dare_full_name"] as? String ?? ""
                
                let creatorData = documentData["creator"] as? [String: Any] ?? ["": ""]
                let creatoruid = creatorData["uid"] as? String ?? ""
                let pathToProfileImage = creatorData["profile_picture_URL"] as? String ?? ""
                let creatorUsername = creatorData["username"] as? String ?? ""
                
                let numberOfLikes = documentData["like_count"] as? Int ?? 0
                let numberOfComments = documentData["comment_count"] as? Int ?? 0
                
                let pathToThumbnail = documentData["thumbnail_image"] as? String ?? ""
                
                let post = Post(postID: postID, creatoruid: creatoruid, dareID: dareID, pathToVideo: pathToVideo, timestamp: timestampDate, pathToProfileImage: pathToProfileImage, creatorUsername: creatorUsername, caption: caption, dareFullName: dareFullName, numberOfLikes: numberOfLikes, numberOfComments: numberOfComments)
                post.pathToThumbnail = pathToThumbnail
                tempPosts.append(post)
            }
            return completion(tempPosts)
        }
    }
    
    // MARK: CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        
        let cellNode = PostCellNode()
        
        cellNode.asset = AVAsset(url: URL(string: posts[indexPath.row].pathToVideo)!)

        cellNode.parentViewController = self
        cellNode.postID = self.posts[indexPath.row].postID
        cellNode.creatoruid = self.posts[indexPath.row].creatoruid
        
        let boldLabelAttributes = Utilities.createAttributes(color: .white, fontSize: 18, bold: true, shadow: true)
        let captionAttributes = Utilities.createAttributes(color: .white, fontSize: 16, bold: false, shadow: true)
        let timestampAttributes = Utilities.createAttributes(color: .lightGray, fontSize: 14, bold: false, shadow: true)
        
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
        fetchPostIDs { (postIDs) in
            self.fetchPosts(postIDs: postIDs) { (newPosts) in
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

