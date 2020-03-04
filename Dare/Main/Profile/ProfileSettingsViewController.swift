//
//  ProfileSettingsViewController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/8/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseAuth

class ProfileSettingsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let reuseIdentifier = "profileSettingsCell"
    var accountFields: [String] = ["Share profile", "Change password"]
    var generalFields: [String] = ["Notifications", "Language"]
    var supportFields: [String] = ["Report a problem", "About"]
    var bottomFields: [String] = ["Clear cache", "Add account", "Log out"]
    var infoFields: [String] = ["Follow and Invite Friends", "Notifications", "Privacy", "Account", "Help", "About", "Report a problem", "Clear cache", "Add account", "Log out", "More", "More", "More", "More", "More", "More", "More", "More", "More"]
    
    // MARK: Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .lightGray
        self.collectionView.register(ProfileSettingsPostCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    // MARK: Functions
    
    func logout(){
        do
        {
            try Auth.auth().signOut()
            
            let navController = UINavigationController()
            let startVC = StartViewController()
            navController.viewControllers = [startVC]
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true, completion: nil)
        }
        catch let error as NSError
        {
            print(error.localizedDescription)
        }
    }
    
    // MARK: CollectionView
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ProfileSettingsPostCell
         cell.infoNameLabel.text = infoFields[indexPath.row]
         return cell
     }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row)
        if indexPath.row == 9 {
            logout()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoFields.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width
        let cellHeight: CGFloat = 45.0
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
