//
//  Post.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-21.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

enum Credit: String {
    case reddit, ninegag, memestar
}

enum MediaType: String {
    case png, jpg, jpeg, gif
}

class Post: NSObject {
    let id: String
    let credit: Credit
    let creditDescription: String
    let postURL: String
    let title: String
    let imageURL: String
    var isLoading: Bool = false
    var mediaType: MediaType
    
    init(credit: Credit, creditDescription: String, postURL: String, title: String, imageURL: String, mediaType: MediaType) {
        self.id = UUID().uuidString
        self.creditDescription = creditDescription
        self.credit = credit
        self.postURL = postURL
        self.title = title
        self.imageURL = imageURL
        self.mediaType = mediaType
    }
    
    func getImageAspectRatio() -> CGFloat? {
        if let image = PhotoManager.shared.loadMediaFor(post: self) {
            return image.size.width / image.size.height
        }
        return nil
    }
    
}
