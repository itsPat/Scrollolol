//
//  NetworkManager.swift
//  CommonKnowledge
//
//  Created by Patrick Trudel on 2019-08-03.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

enum Subreddit: String, CaseIterable {
    case dankmemes, memes, wholesomememes, MemeEconomy
}

enum SubredditModifier: String, CaseIterable {
    case best, hot, top, rising, new, random
}

protocol NetworkManagerDelegate {
    func didFinishFetchingReddit(post: Post)
    func fetchRedditPostDidFail()
}


class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    var isFetchingPosts = false
    var delegate: NetworkManagerDelegate?
    var afterPostFullNames = [String:String]()
    var previouslyFetchedPostURLs = [String:Bool]()
    
    
    
    func fetchPosts(modifier: SubredditModifier, after: Bool) {
        
        if !isFetchingPosts {
            isFetchingPosts = true
            for subreddit in Subreddit.allCases {
                var urlString = "https://api.reddit.com/r/\(subreddit.rawValue)"
                urlString += "/\(modifier.rawValue)"
                urlString += "/.json?"
                urlString += after ? "&after=\(self.afterPostFullNames[subreddit.rawValue] ?? "")" : ""
                urlString += "&limit=3"
                
                print("✅FETCHING NEW DATA WITH URL: \(urlString)✅")
                
                guard let url = URL(string: urlString) else { return }
                
                let task = URLSession.shared.dataTask(with: url) { (data, res, err) in
                    if let err = err {
                        self.delegate?.fetchRedditPostDidFail()
                        print("Failed to get data from \(url) with error: \(err)")
                    }
                    
                    guard let data = data else { return }
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return }
                    guard let jsonData = json["data"] as? [String:Any] else { return }
                    guard let postsJSON = jsonData["children"] as? [[String:Any]] else { return }
                    
                    for postJSON in postsJSON {
                        guard let postData = postJSON["data"] as? [String:Any] else { return }
                        guard let title = postData["title"] as? String else { return }
                        guard let imageURL = postData["url"] as? String else { return }
                        guard let permalink = postData["permalink"] as? String else { return }
                        guard let postID = postData["id"] as? String else { return }
                        self.afterPostFullNames[subreddit.rawValue] = "t3_\(postID)"
                        
                        if imageURL.contains(".png") || imageURL.contains(".jpg") || imageURL.contains(".gif") {
                            
                            let mediaTypeString = String(imageURL.suffix(3))
                            if let mediaType = MediaType(rawValue: mediaTypeString) {
                                let postURL = "https://www.reddit.com\(permalink)"
                                let post = Post(credit: .reddit, creditDescription: "r/\(subreddit.rawValue)", postURL: postURL, title: title, imageURL: imageURL, mediaType: mediaType)
                                self.fetchImageFor(post: post, completion: { (result) in
                                    switch result {
                                    case .success(let post):
                                        print("⭐️DID FETCH POST FROM \(post.credit.rawValue.uppercased())⭐️")
                                        self.delegate?.didFinishFetchingReddit(post: post)
                                    case .failure(let err):
                                        self.delegate?.fetchRedditPostDidFail()
                                        print("Did fail to fetch image with \(err.localizedDescription)")
                                    }
                                })
                                
                            }
                        }
                    }
                }
                task.resume()
            }
            self.isFetchingPosts = false
        }
    }
    
    func fetchImageFor(post: Post, completion: @escaping (Result<Post, Error>) -> ()) {
        if self.previouslyFetchedPostURLs[post.postURL] == nil {
            self.previouslyFetchedPostURLs[post.postURL] = true
            if let url = URL(string: post.imageURL) {
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config)
                
                let downloadTask = session.downloadTask(with: url) { (location, response, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    if let location = location {
                        do {
                            let data = try Data(contentsOf: location)
                            if let media = UIImage(data: data) {
                                post.imageAspectRatio = media.size.width / media.size.height
                                PhotoManager.shared.saveMediaFor(post: post, data: data)
                                completion(.success(post))
                            }
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
                downloadTask.resume()
            }
        }
    }
    
    func fetch9GAGPosts(delegate: XMLManagerDelegate) {
        let paths = [
            "https://www.9gag-rss-feed.ovh/rss/9GAG_Meme_-_Hot.atom"
        ]
        
        for path in paths {
            guard let url = URL(string: path) else { return }
            let task = URLSession.shared.dataTask(with: url) { (data, res, err) in
                if let err = err {
                    print("Failed to get data from \(url) with error: \(err)")
                }
                guard let data = data else { return }
                XMLManager.shared.parse(data: data)
                XMLManager.shared.delegate = delegate
            }
            task.resume()
        }
    }
    
}



