//
//  ProfilePreview.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/9/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

class ProfilePreview : NSObject {
    
    var fullName: String
    var username: String
    var profileImageURL: String
    var uid: String
    var isFollowing: Bool
    var isCurrentUser: Bool = false
    
    init(uid: String, fullName: String, username: String, profileImageURL: String, isFollowing: Bool) {
        self.uid = uid
        self.fullName = fullName
        self.username = username
        self.profileImageURL = profileImageURL
        self.isFollowing = isFollowing
    }
}

