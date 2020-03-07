//
//  DarePageViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/4/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class DarePageViewController: ASViewController<ASDisplayNode>, ASCollectionDataSource, ASCollectionDelegate {
    
    var collectionNode: ASCollectionNode!
    
    var dareID: String!
    var dare = Dare()
    
    // MARK: Initialization and Setup
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        collectionNode.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
        
        super.init(node: collectionNode)
        
        flowLayout.headerReferenceSize = CGSize(width: self.view.bounds.width, height: 110)
        
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        flowLayout.itemSize.width = self.view.bounds.width / 3 - 1
        flowLayout.itemSize.height = flowLayout.itemSize.width * 1.5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.view.allowsSelection = false
        collectionNode.view.backgroundColor = .lightGray
        
        self.view.addSubnode(collectionNode)
        collectionNode.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        FirebaseUtilities.fetchDare(dareID: dareID) { (dare, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
            }
            self.dare = dare!
            DispatchQueue.main.async {
                self.collectionNode.reloadData()
            }
        }
        self.navigationItem.title = dare.dareNameFull
    }
    
    // MARK: Buttons and Actions
    
    @objc func userButtonPressed() {
        let exploreProfileVC = ExploreProfileViewController()
        exploreProfileVC.creatoruid = dare.creatorduid
        self.navigationController?.show(exploreProfileVC, sender: self)
    }
    
    // MARK: CollectionNode
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> ASCellNode {
        let headerCell = DarePageHeaderNodeCell()
        
        let noBoldlabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.systemFont(ofSize: 18)
        ]
        let boldLabelAttributes: [NSAttributedString.Key: Any] = [
             .foregroundColor : UIColor.black,
             .font : UIFont.boldSystemFont(ofSize: 18)
         ]
        
        headerCell.dareImage.url = URL(string: dare.creatorProfilePicturePath ?? "")
        headerCell.dareLabel.attributedText = NSAttributedString(string: dare.dareNameFull ?? "Dare", attributes: boldLabelAttributes)
        let usernameAttributed = NSAttributedString(string: dare.creatorUsername ?? "username", attributes: noBoldlabelAttributes)
        headerCell.userCreatorButton.setAttributedTitle(usernameAttributed, for: .normal)
        headerCell.dareCountLabel.attributedText = NSAttributedString(string: String(dare.numberOfAttempts ?? 0), attributes: noBoldlabelAttributes)
        headerCell.userCreatorButton.addTarget(self, action: #selector(userButtonPressed), forControlEvents: .touchUpInside)
        
        return headerCell
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = ASCellNode()
        cellNode.backgroundColor = .gray
        return cellNode
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return 15
    }
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
}
