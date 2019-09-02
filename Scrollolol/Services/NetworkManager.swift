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

enum Instagram: String, CaseIterable {
    case fuckjerry = "11762801"
    case funnymemes = "2955360060"
    case memes = "300712527"
    case beigecardigan = "32458049"
    
    func accountName() -> String {
        switch self {
        case .fuckjerry:
            return "@fuckjerry"
        case .funnymemes:
            return "@funnymemes"
        case .memes:
            return "@memes"
        case .beigecardigan:
            return "@beigecardigan"
        }
    }
}

protocol NetworkManagerDelegate {
    func didFinishFetching(post: Post)
    func fetchPostDidFail()
}


class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    var isFetchingPosts = false
    var delegate: NetworkManagerDelegate?
    var redditAfterIDs = [String:String]()
    var instagramAfterIDs = [String:String]()
    
    
    
    func fetchRedditPosts(modifier: SubredditModifier, after: Bool) {
        
        if !after {
            redditAfterIDs.removeAll()
        }
        
        if !isFetchingPosts {
            isFetchingPosts = true
            for subreddit in Subreddit.allCases {
                var urlString = "https://api.reddit.com/r/\(subreddit.rawValue)"
                urlString += "/\(modifier.rawValue)"
                urlString += "/.json?"
                urlString += after ? "&after=\(self.redditAfterIDs[subreddit.rawValue] ?? "")" : ""
                urlString += "&limit=3"
                
                print("✅FETCHING NEW DATA WITH URL: \(urlString)✅")
                
                guard let url = URL(string: urlString) else { return }
                
                let task = URLSession.shared.dataTask(with: url) { (data, res, err) in
                    if let err = err {
                        self.delegate?.fetchPostDidFail()
                        print("Failed to get data from \(url) with error: \(err)")
                    }
                    
                    guard let data = data else { return }
                    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return }
                    guard let jsonData = json["data"] as? [String:Any] else { return }
                    guard let postsJSON = jsonData["children"] as? [[String:Any]] else { return }
                    
                    for postJSON in postsJSON {
                        guard let postData = postJSON["data"] as? [String:Any] else { continue }
                        guard let title = postData["title"] as? String else { continue }
                        guard let imageURL = postData["url"] as? String else { continue }
                        guard let permalink = postData["permalink"] as? String else { continue }
                        guard let postID = postData["id"] as? String else { continue }
                        if let mediaType = MediaType(rawValue: imageURL.components(separatedBy: .punctuationCharacters).last ?? "") {
                            self.redditAfterIDs[subreddit.rawValue] = "t3_\(postID)"
                            let postURL = "https://www.reddit.com\(permalink)"
                            let post = Post(id: postID, credit: .reddit, creditDescription: "r/\(subreddit.rawValue)", postURL: postURL, title: title, imageURL: imageURL, mediaType: mediaType)
                            self.fetchImageFor(post: post, completion: { (result) in
                                switch result {
                                case .success(let post):
                                    self.delegate?.didFinishFetching(post: post)
                                case .failure(let err):
                                    self.delegate?.fetchPostDidFail()
                                    print("Did fail to fetch image with \(err.localizedDescription)")
                                }
                            })
                        }
                    }
                }
                task.resume()
            }
            self.isFetchingPosts = false
        }
    }
    
    func fetchInstagramPosts(after: Bool) {
        if !after {
            instagramAfterIDs.removeAll()
        }
        for instagram in Instagram.allCases {
            let urlString = "https://www.instagram.com/graphql/query/?query_hash=472f257a40c653c64c666ce877d59d2b&variables={\"id\":\"\(instagram.rawValue)\",\"first\":3,\"after\":\"\(self.instagramAfterIDs[instagram.rawValue] ?? "")\"}"
            
            guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else { return }
            
            print("✅FETCHING NEW DATA WITH URL: \(url.absoluteString)✅")
            
            let task = URLSession.shared.dataTask(with: url) { (data, res, err) in
                if let err = err {
                    self.delegate?.fetchPostDidFail()
                    print("Failed to get data from \(url) with error: \(err)")
                }
                
                guard let data = data else { return }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return }
                guard let dataDict = json["data"] as? [String:Any] else { return }
                guard let userDict = dataDict["user"] as? [String:Any] else { return }
                guard let timelineMediaDict = userDict["edge_owner_to_timeline_media"] as? [String:Any] else { return }
                guard let pageInfo = timelineMediaDict["page_info"] as? [String:Any] else { return }
                guard let endCursor = pageInfo["end_cursor"] as? String else { return }
                guard let postsJSON = timelineMediaDict["edges"] as? [[String:Any]] else { return }
  
                
                for postJSON in postsJSON {
                    guard let nodeData = postJSON["node"] as? [String:Any] else { continue }
                    guard let edgeMedia = nodeData["edge_media_to_caption"] as? [String:Any] else { continue }
                    guard let shortcode = nodeData["shortcode"] as? String else { continue }
                    let postURL = "https://www.instagram.com/p/\(shortcode)/"
                    guard let imageURL = nodeData["display_url"] as? String else { continue }
                    guard let isVideo = nodeData["is_video"] as? Bool else { continue }
                    guard let firstEdge = (edgeMedia["edges"] as? [[String:Any]])?.first else { continue }
                    guard let edgeNode = firstEdge["node"] as? [String:String] else { continue }
                    guard let title = edgeNode["text"] else { continue }
                    guard isVideo == false else { continue }
                    
                    var mediaType: MediaType? = nil
                    
                    if imageURL.contains(".jpg") {
                        mediaType = .jpg
                    } else if imageURL.contains(".png") {
                        mediaType = .png
                    } else if imageURL.contains(".gif") {
                        mediaType = .gif
                    }
                    
                    if let mediaType = mediaType {
                        self.instagramAfterIDs[instagram.rawValue] = endCursor
                        let post = Post(id: shortcode, credit: .instagram, creditDescription: instagram.accountName(), postURL: postURL, title: title, imageURL: imageURL, mediaType: mediaType)
                        self.fetchImageFor(post: post, completion: { (result) in
                            switch result {
                            case .success(let post):
                                self.delegate?.didFinishFetching(post: post)
                            case .failure(let err):
                                self.delegate?.fetchPostDidFail()
                                print("Did fail to fetch image with \(err.localizedDescription)")
                            }
                        })
                    }
                }
            }
            task.resume()
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
    
    func fetchImageFor(post: Post, completion: @escaping (Result<Post, Error>) -> ()) {
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
                            print("MEDIA SIZE: W: \(media.size.width), H: \(media.size.height)")
                            PhotoManager.shared.saveMediaFor(post: post, data: data, completion: { (result) in
                                switch result {
                                case .success(let imageURL):
                                    post.imagePath = imageURL.path
                                    completion(.success(post))
                                case .failure(let err):
                                    print("FAILED WITH ERROR \(err.localizedDescription).")
                                    completion(.failure(err))
                                }
                            })
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



