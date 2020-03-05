//
//  ChooseDareViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/29/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

let categoriesCellID = "CategoriesCellID"
let draftsCellID = "DraftsCellID"
let savedCellID = "SavedCellID"

class ChooseDareViewController: UIViewController {
    
    let cellText: [String] = ["Trending", "Friends", "Featured", "Local", "Learn", "Adventurous", "Promoted", "My dares"]
    
    var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentSize.height = 700
        view.backgroundColor = UIColor.white
        return view
    }()
    
    var daresLabel: UILabel!
    var exitButton: UIButton!
    var searchBar: UISearchBar!
    var segmentedControl: UISegmentedControl!
    
    var randomDareImageButton: UIButton!
    var categoriesLabel: UILabel!
    var categoriesCollectionView: UICollectionView!
    var draftsLabel: UILabel!
    var draftsCollectionView: UICollectionView!
    var draftsCollectionDataDelegate = DraftsCollectionDataDelegate()
    
    var savedCollectionView: UICollectionView!
    var savedCollectionDataDelegate = SavedCollectionDataDelegate()
        
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpExploreElements()
        setUpExploreConstraints()
        
        setUpSavedElements()
        setUpSavedConstraints()
        
        hideKeyboardWhenTappedAround()
    }
    
    func setUpExploreElements() {
        view.backgroundColor = .white
        
        exitButton = UIButton(type: .system)
        let exitImage = UIImage(named: "exit_cross")
        exitButton.setImage(exitImage, for: .normal)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.addTarget(self, action: #selector(exitTouchUpInside), for: .touchUpInside)
        view.addSubview(exitButton)
        
        daresLabel = UILabel()
        daresLabel.text = "Dares"
        daresLabel.font = UIFont.boldSystemFont(ofSize: 20)
        daresLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(daresLabel)
        
        searchBar = UISearchBar()
        searchBar.tintColor = .gray
        searchBar.barTintColor = .white
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        segmentedControl = UISegmentedControl(items: ["Discover", "Saved"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.setWidth(view.bounds.width / 2 - 15, forSegmentAt: 0)
        segmentedControl.setWidth(view.bounds.width / 2 - 15, forSegmentAt: 1)
        segmentedControl.addTarget(self, action: #selector(segmentedControlSwitched), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addUnderlineForSelectedSegment()
        view.addSubview(segmentedControl)
        
        view.insertSubview(scrollView, at: 0)
        let contentRect: CGRect = scrollView.subviews.reduce(into: .zero) { rect, view in
            rect = rect.union(view.frame)
        }
        scrollView.contentSize = contentRect.size
        print(contentRect.size.height)
        
        randomDareImageButton = UIButton()
        let randomDareImage = UIImage(named: "Random_Dare")
        randomDareImageButton.setImage(randomDareImage, for: .normal)
        randomDareImageButton.translatesAutoresizingMaskIntoConstraints = false
        randomDareImageButton.addTarget(self, action: #selector(randomDarePressed), for: .touchUpInside)
        scrollView.addSubview(randomDareImageButton)
        
        categoriesLabel = UILabel()
        categoriesLabel.text = "Categories"
        categoriesLabel.font = UIFont.boldSystemFont(ofSize: 20)
        categoriesLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(categoriesLabel)
        
        let categoriesLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        categoriesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: categoriesLayout)
        categoriesCollectionView.delegate = self
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.register(CategoriesCollectionCell.self, forCellWithReuseIdentifier: categoriesCellID)
        categoriesCollectionView.backgroundColor = .white
        categoriesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(categoriesCollectionView)
        
        draftsLabel = UILabel()
        draftsLabel.text = "Drafts"
        draftsLabel.font = UIFont.boldSystemFont(ofSize: 20)
        draftsLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(draftsLabel)
        
        let draftsLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        draftsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: draftsLayout)
        draftsCollectionView.delegate = draftsCollectionDataDelegate
        draftsCollectionView.dataSource = draftsCollectionDataDelegate
        draftsCollectionView.register(DraftsCollectionCell.self, forCellWithReuseIdentifier: draftsCellID)
        draftsCollectionView.backgroundColor = .white
        draftsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(draftsCollectionView)
    }
    
    func setUpSavedElements() {
        let savedLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        savedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: savedLayout)
        savedCollectionView.delegate = savedCollectionDataDelegate
        savedCollectionView.dataSource = savedCollectionDataDelegate
        savedCollectionView.register(SavedCollectionCell.self, forCellWithReuseIdentifier: savedCellID)
        savedCollectionView.backgroundColor = .lightGray
        savedCollectionView.isHidden = true
        savedCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(savedCollectionView)
    }
    
    // MARK:-Layout
    
    func setUpExploreConstraints() {
        let randomDareWidth = self.view.bounds.width - 20.0
        NSLayoutConstraint.activate([
            exitButton.heightAnchor.constraint(equalToConstant: 30),
            exitButton.widthAnchor.constraint(equalToConstant: 30),
            exitButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            exitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            
            daresLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            daresLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            searchBar.topAnchor.constraint(equalTo: daresLabel.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            randomDareImageButton.heightAnchor.constraint(equalToConstant: randomDareWidth * (310 / 1088)),
            randomDareImageButton.widthAnchor.constraint(equalToConstant: randomDareWidth),
            randomDareImageButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 15),
            randomDareImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            categoriesLabel.topAnchor.constraint(equalTo: randomDareImageButton.bottomAnchor, constant: 10),
            categoriesLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            categoriesCollectionView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 10),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: view.bounds.width / 2),
            
            draftsLabel.topAnchor.constraint(equalTo: categoriesCollectionView.bottomAnchor, constant: 10),
            draftsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            draftsCollectionView.topAnchor.constraint(equalTo: draftsLabel.bottomAnchor, constant: 10),
            draftsCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            draftsCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            draftsCollectionView.heightAnchor.constraint(equalToConstant: view.bounds.width / 2),
            draftsCollectionView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10)
        ])
    }
    
    func setUpSavedConstraints() {
        NSLayoutConstraint.activate([
            savedCollectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 5),
            savedCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            savedCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            savedCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK:-Buttons and Actions
    
    @objc func exitTouchUpInside() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func segmentedControlSwitched() {
        segmentedControl.changeUnderlinePosition()
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            savedCollectionView.isHidden = true
            scrollView.isHidden = false
        case 1:
            savedCollectionView.isHidden = false
            scrollView.isHidden = true
        default:
            break
        }
    }
    
    @objc func randomDarePressed() {
        print("random dare pressed")
    }
}

// MARK:-Explore CollectionView

extension ChooseDareViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let red = UIColor(red: 255/255, green: 125/255, blue: 125/255, alpha: 1)
        let lightBlue = UIColor(red: 117/255, green: 219/255, blue: 240/255, alpha: 1)
        let orange = UIColor(red: 255/255, green: 167/255, blue: 116/255, alpha: 1)
        let purple = UIColor(red: 124/255, green: 117/255, blue: 255/255, alpha: 1)
        let yellow = UIColor(red: 228/255, green: 216/255, blue: 93/255, alpha: 1)
        let pink = UIColor(red: 255/255, green: 127/255, blue: 250/255, alpha: 1)
        let green = UIColor(red: 113/255, green: 180/255, blue: 99/255, alpha: 1)
        
        let cellColors: [UIColor] = [red, lightBlue, orange, purple, yellow, pink, green, red]
        
        let categoriesCell = collectionView.dequeueReusableCell(withReuseIdentifier: categoriesCellID, for: indexPath) as! CategoriesCollectionCell
        categoriesCell.backgroundColor = cellColors[indexPath.row]
        categoriesCell.categoryLabel.text = cellText[indexPath.row]
        return categoriesCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected item at \(indexPath.row)")
        let dareCategoryVC = DareCategoryViewController()
        dareCategoryVC.category = cellText[indexPath.row]
        self.navigationController?.show(dareCategoryVC, sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width/2.0 - 5
        let cellHeight = cellWidth / 4
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
}

// MARK: - Drafts CollectionView

class DraftsCollectionDataDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let categoriesCell = collectionView.dequeueReusableCell(withReuseIdentifier: draftsCellID, for: indexPath) as! DraftsCollectionCell
        categoriesCell.backgroundColor = .gray
        return categoriesCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width/3.0 - 4
        let cellHeight = cellWidth * 1.5
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
}

// MARK: - Saved CollectionView

class SavedCollectionDataDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let categoriesCell = collectionView.dequeueReusableCell(withReuseIdentifier: savedCellID, for: indexPath) as! SavedCollectionCell
        return categoriesCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath.row) dare")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width
        let cellHeight = cellWidth / 6
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
