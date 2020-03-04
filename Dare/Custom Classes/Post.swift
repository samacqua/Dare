//
//  Post.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

class Post : NSObject {
    
    var postID: String
    var creatoruid: String
    var dareID: String
    
    var timestamp: Date
    
    var pathToVideo: String
    var pathToProfileImage: String

    var creatorUsername: String
    var caption: String
    var dareFullName: String

    var numberOfLikes: Int
    var numberOfComments: Int
    
    var pathToThumbnail: String!
    var isLiked: Bool!
        
    init(postID: String, creatoruid: String, dareID: String, pathToVideo: String, timestamp: Date, pathToProfileImage: String, creatorUsername: String, caption: String, dareFullName: String, numberOfLikes: Int, numberOfComments: Int) {
        self.postID = postID
        self.creatoruid = creatoruid
        self.dareID = dareID
        self.timestamp = timestamp
        self.pathToVideo = pathToVideo
        self.pathToProfileImage = pathToProfileImage
        self.creatorUsername = creatorUsername
        self.caption = caption
        self.dareFullName = dareFullName
        self.numberOfLikes = numberOfLikes
        self.numberOfComments = numberOfComments
    }
}
