//
//  Comment.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

class Comment: NSObject {
    var uid: String
    var profilePictureURL: String
    var username: String
    var comment: String
    var numberOfLikes: Int
    var commentID: String
    
    init(uid: String, profilePictureURL: String, username: String, comment: String, numberOfLikes: Int, commentID: String) {
        self.uid = uid
        self.profilePictureURL = profilePictureURL
        self.username = username
        self.comment = comment
        self.numberOfLikes = numberOfLikes
        self.commentID = commentID
    }
}
