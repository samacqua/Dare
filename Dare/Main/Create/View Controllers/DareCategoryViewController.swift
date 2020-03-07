//
//  DareCategoryViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/2/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit

class DareCategoryViewController: ASViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource {
    
    var category: String!
    var headerView: UIView!
    var exitButton: UIButton!
    var headerTitle: UILabel!
    
    var dares = [Dare]()

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
        FirebaseUtilities.fetchDaresInCategory(category: category!) { (dares, error) in
            if error != nil {
                self.view.showToast(message: error!.localizedDescription)
                return
            }
            self.dares = dares!
            self.tableNode.reloadData()
        }
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
