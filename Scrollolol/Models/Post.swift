//
//  Post.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-21.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

enum Credit: String {
    case reddit, ninegag
}

class Post: NSObject {
    let credit: Credit
    let creditDescription: String
    let postURL: String
    let title: String
    let imageURL: String
    var image: UIImage? = nil
    var isLoading: Bool = false
    
    init(credit: Credit, creditDescription: String, postURL: String, title: String, imageURL: String) {
        self.creditDescription = creditDescription
        self.credit = credit
        self.postURL = postURL
        self.title = title
        self.imageURL = imageURL
    }
    
    func getImageAspectRatio() -> CGFloat? {
        guard let image = image else { return nil }
        return image.size.width / image.size.height
    }
    
}

class RedditPost: Post {
    
}