//
//  CreateDareCell.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/13/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class CreateDareView: UIView {
    
    var parentVC: UIViewController!
    var dareTitle: String!
    
    var collectionView: UICollectionView!
    var cellID = "Cell ID"
    var headerID = "Header ID"
    
    let cellTitles = ["Dare who?", "Location", "Tags"]
    let cellInfo = ["Everyone", "My location", "None"]
    
    var createButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUpElements()
        setUpConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var bottomConstraint: NSLayoutConstraint?
    
    func setUpElements() {
        self.backgroundColor = .white
        
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CreateDareCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.register(CreateDareHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerID)
        collectionView.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(collectionView)
        
        createButton = UIButton(type: .system)
        createButton.setTitle("Create dare", for: .normal)
        Utilities.styleFilledButton(createButton)
        createButton.backgroundColor = .gray
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createButtonPressed), for: .touchUpInside)
        self.addSubview(createButton)
        
        bottomConstraint = NSLayoutConstraint(item: createButton!, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -15.0)
        self.addConstraint(bottomConstraint!)
    }
    
    func setUpConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            createButton.heightAnchor.constraint(equalToConstant: 53),
            createButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let rect = keyboardFrame.cgRectValue
                
                let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
                
                if isKeyboardShowing {
                    bottomConstraint?.constant = -rect.height - 5
                    self.addConstraint(bottomConstraint!)
                } else {
                    bottomConstraint?.constant = -15.0
                    self.addConstraint(bottomConstraint!)
                }

                UIView.animate(withDuration: 0, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                    self.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    @objc func createButtonPressed() {
        guard let dareTitle = dareTitle else { return }
        FirebaseUtilities.createDare(dareTitle: dareTitle) { (error) in
            if error != nil {
                self.showToast(message: error!.localizedDescription)
            } else {
                let homeVC = MainTabBarController()
                homeVC.modalPresentationStyle = .fullScreen
                self.parentVC.self.present(homeVC, animated: true, completion: nil)
            }
        }
    }
    
    @objc func textFieldChanged(_ textField: UITextField) {
        let text = textField.text
        dareTitle = textField.text ?? ""
        if text != nil && text != "" {
            createButton.isEnabled = true
            createButton.backgroundColor = .orange
        } else {
            createButton.isEnabled = false
            createButton.backgroundColor = .gray
        }
    }
}

extension CreateDareView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! CreateDareCell
        cell.cellLabel.text = cellTitles[indexPath.row]
        cell.cellInfoLabel.text = cellInfo[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width
        let cellHeight: CGFloat = 50.0
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerID, for: indexPath) as! CreateDareHeaderView
        headerView.createDareTextField.addTarget(self, action: #selector(self.textFieldChanged(_:)), for: .allEditingEvents)
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let cellWidth = collectionView.bounds.width
        let cellHeight: CGFloat = 95.0
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.showToast(message: cellTitles[indexPath.row])
    }
}

class CreateDareHeaderView: UICollectionReusableView {
    
    var createDareLabel: UILabel!
    var createDareTextField: UITextField!
    var dareTextFieldHeight: CGFloat = 40.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        createDareLabel = UILabel()
        createDareLabel.text = "Create a Dare to..."
        createDareLabel.font = UIFont.boldSystemFont(ofSize: 32)
        createDareLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(createDareLabel)
        
        createDareTextField = UITextField()
        let index = Int.random(in: 0 ..< Constants.exampleDares.count)
        createDareTextField.placeholder = Constants.exampleDares[index]
        createDareTextField.minimumFontSize = 18
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: dareTextFieldHeight - 2, width: self.frame.width - 20, height: 2)
        bottomLine.backgroundColor = Utilities.returnColor().cgColor
        createDareTextField.borderStyle = .none
        createDareTextField.layer.addSublayer(bottomLine)
        createDareTextField.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(createDareTextField)
        
        let headerBottomLine = CALayer()
        headerBottomLine.frame = CGRect(x: 0, y: self.bounds.height - 1, width: self.frame.width, height: 1)
        headerBottomLine.backgroundColor = UIColor(white: 0.97, alpha: 1.0).cgColor
        
        NSLayoutConstraint.activate([
            createDareLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            createDareLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            
            createDareTextField.topAnchor.constraint(equalTo: createDareLabel.bottomAnchor, constant: 10),
            createDareTextField.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            createDareTextField.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            createDareTextField.heightAnchor.constraint(equalToConstant: dareTextFieldHeight)
        ])
    }
}

class CreateDareCell: UICollectionViewCell {
    
    var cellLabel: UILabel!
    var cellInfoLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpElements()
    }
    
    func setUpElements() {
        self.backgroundColor = .white
        
        cellLabel = UILabel()
        cellLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(cellLabel)
        
        cellInfoLabel = UILabel()
        cellInfoLabel.textColor = .lightGray
        cellInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(cellInfoLabel)
        
        NSLayoutConstraint.activate([
            cellLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            cellLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            cellInfoLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            cellInfoLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
