//
//  DareCategoryViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/2/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseFirestore
import FirebaseStorage

class DareCategoryViewController: ASViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource {
    
    var category: String!
    var headerView: UIView!
    var exitButton: UIButton!
    var headerTitle: UILabel!
    
    var dares = [Dare]()
    
    let database = Firestore.firestore()
    let storageRef = Storage.storage().reference()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
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
        tableNode.view.backgroundColor = .gray
        
        setUpHeaderView()
        fetchDares()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerTitle.text = category
    }
    
    func setUpHeaderView() {
        headerView = UIView()
        headerView.backgroundColor = .white
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        headerView.addSubview(exitButton)
        
        headerTitle = UILabel()
        headerTitle.text = "Dares"
        headerTitle.font = UIFont.boldSystemFont(ofSize: 20)
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerTitle)
        
        NSLayoutConstraint.activate([
            exitButton.heightAnchor.constraint(equalToConstant: 30),
            exitButton.widthAnchor.constraint(equalToConstant: 30),
            exitButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            exitButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            
            headerTitle.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            headerTitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
        ])
    }
    
    // MARK: - Actions
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Functions
    
    func fetchDares() {
        print("Category:", self.category!.lowercased())
        database.collection("universal_dare_categories").document(self.category!.lowercased()).getDocument { (document, error) in
            if error != nil {
                print("Error getting Dare category (\(self.category!)) document:", error!)
            }
            
            guard let data = document?.data() else { return }
            print("Document data:", data)
            for (identifier, name) in data {
                print("identifier:", identifier)
                print("name:", name)
                let stringName = name as! String
                let dare = Dare()
                dare.dareNameID = stringName
                self.database.collection("dares").document(stringName).getDocument { (document2, error2) in
                    if error2 != nil {
                        print("Error getting dare from category \(self.category!):", error2!)
                    }
                    
                    guard let dareData = document2?.data() else { return }
                    print("Dare data:", dareData)
                    
                    dare.creatorProfilePicturePath = dareData["creator_profile_picture"] as? String ?? ""
                    dare.numberOfAttempts = dareData["number_of_attempts"] as? Int ?? 0
                    dare.dareNameFull = dareData["dare_full_name"] as? String ?? "Dare"
                    
                    self.dares.append(dare)
                    print("Dare appended")
                    DispatchQueue.main.async {
                        self.tableNode.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - TableNode
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cellNode = CategoryTableCellNode()
        
        let dareLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.boldSystemFont(ofSize: 20)
        ]
        
        let countLabelAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.gray,
            .font : UIFont.systemFont(ofSize: 10)
        ]
        
        cellNode.mainLabel.attributedText = NSAttributedString(string: self.dares[indexPath.row].dareNameFull, attributes: dareLabelAttributes)
        cellNode.secondaryLabel.attributedText = NSAttributedString(string: String(self.dares[indexPath.row].numberOfAttempts), attributes: countLabelAttributes)
        cellNode.profileImageView.url = URL(string: self.dares[indexPath.row].creatorProfilePicturePath)
        return cellNode
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
//        let dareCameraVC = DareCameraViewController()
//        dareCameraVC.dare = self.dares[indexPath.row]
//        present(dareCameraVC, animated: true, completion: nil)
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.dares.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
