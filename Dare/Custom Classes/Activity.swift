//
//  Activity.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/18/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

class Activity: NSObject {
    var uid: String
    var profilePictureURL: String
    var username: String
    
    var type: String
    
    var thumbnailPictureURL: String!
    var comment: String!
    var postID: String!
    
    var isCurrentUserFollowing: Bool!
    
    var timestamp: Date
    
    init(uid: String, profilePictureURL: String, username: String, type: String, timestamp: Date) {
        self.uid = uid
        self.profilePictureURL = profilePictureURL
        self.username = username
        self.type = type
        self.timestamp = timestamp
    }
}
