//
//  CommentViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import AsyncDisplayKit
import FirebaseFirestore
import FirebaseAuth

class CommentViewController: ASViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource, UITextViewDelegate, HalfModalPresentable {
    
    var postID: String!
    
    var footerView: UIView!
    var textView: UITextView!
    var sendButton: UIButton = {
       let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendButtonTouchUpInside), for: .touchUpInside)
        return button
    }()
    
    var comments = [Comment]()
    
    let database = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    
    var reachedEnd: Bool = false
    
    var tableNode: ASTableNode {
        return node as! ASTableNode
    }
    
    init() {
        super.init(node: ASTableNode())
        tableNode.delegate = self
        tableNode.dataSource = self
        setUpFooterView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Comments"
        
        tableNode.view.allowsSelection = true
        tableNode.view.separatorStyle = .singleLine
        tableNode.view.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    var bottomConstraint: NSLayoutConstraint?
    
    func setUpFooterView() {
        footerView = UIView()
        footerView.backgroundColor = .lightGray
        footerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(footerView)
        bottomConstraint = NSLayoutConstraint(item: footerView!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        view.addConstraintsWithFormat(format: "V:[v0(44)]", views: footerView)
        
        view.addConstraint(bottomConstraint!)
        
        textView = UITextView()
        textView.text = "Comment"
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .gray
        textView.returnKeyType = .send
        textView.enablesReturnKeyAutomatically = true
        
        textView.layer.cornerRadius = 27 / 2.0
        textView.layer.masksToBounds = true
        
        textView.backgroundColor = .white
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(textView)
        
        footerView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            
            footerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            footerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            
            textView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 3),
            textView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -4),
            textView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 3),
            textView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -55),
            
            sendButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 3),
            sendButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -4),
            sendButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -6),
        ])
    }
    
    // MARK: - Actions
    
    @objc func sendButtonTouchUpInside() {
        if textView.text != "" && textView.text != "Comment" {
            self.dismissKeyboard()
            sendCommentToDatabase()
            textView.text = "Comment"
            textView.textColor = UIColor.lightGray
        }
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let rect = keyboardFrame.cgRectValue

                let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
                
                bottomConstraint?.constant = isKeyboardShowing ? -rect.height : 0
                
                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    @objc func exitTouchUpInside() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Functions
    
    func getCommenterInfo(completion: @escaping(_ profilePictureURL: String, _ username: String) -> ()) {
        database.collection("users").document(uid).getDocument { (document, error) in
            if error != nil {
                print("Error retrieving current user's information:", error!)
            }
            guard let data = document?.data() else { return }
            let username = data["username"] as? String ?? ""
            let profilePictureURL = data["profile_image"] as? String ?? ""
            return completion(profilePictureURL, username)
        }
    }
    
    func sendCommentToDatabase() {
        let batch = database.batch()
        
        let commentText = textView.text!
        
        getCommenterInfo { (profilePictureURL, username) in
            
            let postPath = self.database.collection("posts").document(self.postID)
            batch.updateData(["number_of_comments": FieldValue.increment(Int64(1))], forDocument: postPath)
            
            let commentPath = postPath.collection("comments").document()
            
            let commenter = ["profile_picture_URL": profilePictureURL, "uid": self.uid, "username": username]
            let commentData: [String: Any] = ["comment_ID": commentPath.documentID, "comment_text": commentText, "commenter": commenter, "number_of_likes": Int(0)]
            batch.setData(commentData, forDocument: commentPath)
            
            batch.commit()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Comment" {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Comment"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func fetchComments(completion: @escaping(_ comments:[Comment]) -> ()) {
        
        let commentsRef = database.collection("posts").document(postID).collection("comments").order(by: "number_of_likes", descending: true)
        let lastComment = self.comments.last
        var queryRef: Query
        
        if lastComment == nil {
            queryRef = commentsRef.limit(to: 8)
        } else {
            let lastNumberOfLikes = lastComment!.numberOfLikes
            queryRef = commentsRef.start(after: [lastNumberOfLikes]).limit(to: 8)
        }
        
        queryRef.getDocuments { (snapshot, error) in
            if error != nil {
                print("Error getting comments:", error!)
            }
            
            guard let unwrappedSnapshot = snapshot else { return }
            let documents = unwrappedSnapshot.documents
            
            var tempComments = [Comment]()
            
            for document in documents {
                
                let documentData = document.data()
                
                let commenterData = documentData["commenter"] as? [String: Any] ?? ["": ""]
                
                let commenteruid = commenterData["uid"] as? String ?? ""
                let commenterProfilePictureURL = commenterData["profile_picture_URL"] as? String ?? ""
                let commenterUsername = commenterData["username"] as? String ?? ""

                let numberOfLikes = documentData["number_of_likes"] as? Int ?? 0
                let commentText = documentData["comment_text"] as? String ?? ""
                
                let commentID = documentData["comment_ID"] as? String ?? ""
                
                if commentID != lastComment?.commentID {
                    let comment = Comment(uid: commenteruid, profilePictureURL: commenterProfilePictureURL, username: commenterUsername, comment: commentText, numberOfLikes: numberOfLikes, commentID: commentID)
                    tempComments.append(comment)
                }
            }
            return completion(tempComments)
        }
    }
    
    // MARK: - TableNode
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        
        let cellNode = CommentCellNode()
        
        let usernameAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.lightGray,
            .font : UIFont.boldSystemFont(ofSize: 14)
        ]
        
        let commentAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : UIColor.black,
            .font : UIFont.systemFont(ofSize: 16)
        ]
        
        let usernameText = self.comments[indexPath.row].username
        cellNode.usernameLabel.attributedText = NSAttributedString(string: usernameText, attributes: usernameAttributes)
        
        let commentText = self.comments[indexPath.row].comment
        cellNode.commentLabel.attributedText = NSAttributedString(string: commentText, attributes: commentAttributes)
        cellNode.profileImageView.url = URL(string: comments[indexPath.row].profilePictureURL)
        
        return cellNode
    }
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let commenteruid = self.comments[indexPath.row].uid
        if commenteruid != uid {
            let exploreProfileVC = ExploreProfileViewController()
            exploreProfileVC.creatoruid = commenteruid
            maximizeToFullScreen()
            navigationController?.show(exploreProfileVC, sender: self)
        } else {
            let profileVC = ProfileViewController()
            maximizeToFullScreen()
            navigationController?.show(profileVC, sender: self)
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    // MARK: - Texture Batch Fetch
    
    func shouldBatchFetch(for tableNode: ASTableNode) -> Bool {
        if !self.reachedEnd {
            return true
        }
        return false
    }
    
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        print("called batch fetch")
        fetchComments { (newComments) in
            
            self.comments.append(contentsOf: newComments)
            
            self.reachedEnd = newComments.count == 0
            
            if !self.reachedEnd {
                let newCommentsCount = newComments.count
                print("New comments count:", newCommentsCount)
                
                print("Complete comments count:", self.comments.count)
                
                if self.comments.count - newCommentsCount > 0 {
                    let indexRange = (self.comments.count - newCommentsCount..<self.comments.count)
                    let indexPaths = indexRange.map { IndexPath(row: $0, section: 0) }
                    tableNode.insertRows(at: indexPaths, with: .left)
                    self.tableNode.reloadRows(at: indexPaths, with: .left)
                    context.completeBatchFetching(true)
                } else {
                    self.tableNode.reloadData()
                    context.completeBatchFetching(true)
                }
            } else {
                context.completeBatchFetching(false)
            }
        }
    }
}
