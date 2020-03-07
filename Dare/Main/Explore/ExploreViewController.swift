//
//  ExploreViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class ExploreViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var flowLayout: UICollectionViewFlowLayout!
    var collectionNode: ASCollectionNode!
    
    var postPreviews = [PostPreview]()
        
    // MARK: - Initialization and Setup
    
    // Setup collectionNode layout
    init() {
        flowLayout = UICollectionViewFlowLayout()
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        
        super.init(node: collectionNode)
        
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.itemSize.width = self.view.bounds.width / 3 - 1
        flowLayout.itemSize.height = flowLayout.itemSize.width * 1.5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Set up collectionNode delegate/datasource and view properties
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Explore"
        self.tabBarItem.title = nil
        
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.view.allowsSelection = true
        collectionNode.view.backgroundColor = UIColor.white
        collectionNode.showsVerticalScrollIndicator = false
        collectionNode.leadingScreensForBatching = 2.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavBar()
    }
    
    func setUpNavBar() {        
        let searchController = UISearchController(searchResultsController: ExploreSearchViewController())
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.searchBar.placeholder = "Search"
        definesPresentationContext = true
    }
    
    // MARK: - CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = ExploreCellNode()
//        cellNode.thumbnailImage.url = URL(string: self.postPreviews[indexPath.row].thumbnailImageURL)     // TODO: Cloud function to reduce size of thumbnail images
        return cellNode
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return postPreviews.count
    }
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let postSelectedVC = ExplorePostSelectedViewController()
        postSelectedVC.postSelectedPreview = postPreviews[indexPath.row]
        postSelectedVC.postIndexPathRow = indexPath.row
        self.navigationController?.show(postSelectedVC, sender: self)
    }
    
    // MARK: - Texture Batch Fetch
    
    func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        return true
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        FirebaseUtilities.getExplorePostPreviews { (newPostPreviews, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            guard let newPostPreviews = newPostPreviews else { return }
            self.postPreviews.append(contentsOf: newPostPreviews)
            self.collectionNode.reloadData()
            context.completeBatchFetching(true)
        }
    }
    
}
