//
//  Constants.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    
    static let placeholderAssetURL = URL(string: "http://www.w3schools.com/html/mov_bbb.mp4")!
    
    // Colors
    
    static let collectionViewBackgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    // Shadows
    
    static let defaultShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = CGSize(width: 0, height: 0)
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
        return shadow
    }()
    
    // NSAttributes
    
    static let whiteBold18: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.white,
        .font : UIFont.boldSystemFont(ofSize: 18)
    ]
    
    static let whiteBoldShadowed18Attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.white,
        .font : UIFont.boldSystemFont(ofSize: 18),
        .shadow : defaultShadow
    ]
    
    static let whiteShadowed16Attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.white,
        .font : UIFont.systemFont(ofSize: 16),
        .shadow : defaultShadow
    ]
    
    static let lightGray14: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.lightGray,
        .font : UIFont.systemFont(ofSize: 14),
    ]
    
    static let lightGrayShadowed14: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.lightGray,
        .font : UIFont.systemFont(ofSize: 14),
        .shadow: defaultShadow
    ]
    
    static let darkGray16: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.darkGray,
        .font : UIFont.systemFont(ofSize: 16)
    ]
    
    static let black14: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.black,
        .font : UIFont.systemFont(ofSize: 14)
    ]
    
    static let blackBold14: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.black,
        .font : UIFont.boldSystemFont(ofSize: 14)
    ]
    
    static let blackBold16: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.black,
        .font : UIFont.boldSystemFont(ofSize: 16)
    ]
    
    static let blackBold26: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.black,
        .font : UIFont.boldSystemFont(ofSize: 26)
    ]
    
    static let orangeBold18: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.orange,
        .font : UIFont.boldSystemFont(ofSize: 18)
    ]
    
    // Edit Profile
    
    static let profileInfoTitle = "Profile Info"
    static let privateInfoTitle = "Private Info"
    static let loginTypeTitle = "Link Login Types"
    
    // Provider IDs
    
    static let passwordProviderID = "password"
    static let facebookProviderID = "facebook.com"
    static let googleProviderID = "google.com"
    
    // Edit Profile Header Titles
    
    static let emailPassword = "Email/Password"
    static let facebook = "Facebook"
    static let google = "Google"
    static let phoneNumber = "Phone Number"
    
}
