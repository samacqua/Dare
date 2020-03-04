//
//  PostThumbnail.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/8/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

class PostPreview : NSObject {
    
    var postID: String
    var thumbnailImageURL: String
        
    init(postID: String, thumbnailImageURL: String) {
        self.postID = postID
        self.thumbnailImageURL = thumbnailImageURL
    }
}
