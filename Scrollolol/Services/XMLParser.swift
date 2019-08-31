//
//  XMLParser.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-25.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

protocol XMLManagerDelegate {
    func didFinishFetching9GAG(post: Post)
}

class XMLManager: NSObject {
    static let shared = XMLManager()
    var delegate: XMLManagerDelegate?
    var elementName = ""
    var postID = ""
    var postURL = ""
    var title = ""
    var imageURL = ""
    
    func parse(data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
}

extension XMLManager: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "entry" {
            postID = ""
            postURL = ""
            title = ""
            imageURL = ""
        }
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "entry",
            imageURL.contains(".png") || imageURL.contains(".jpg") {
            let mediaTypeString = String(imageURL.suffix(3))
            if let mediaType = MediaType(rawValue: mediaTypeString) {
                NetworkManager.shared.fetchImageFor(post: Post(credit: .ninegag, creditDescription: "9GAG/meme", postURL: postURL, title: title.htmlDecoded, imageURL: imageURL, mediaType: mediaType)) { (result) in
                    switch result {
                    case .success(let post):
                        self.delegate?.didFinishFetching9GAG(post: post)
                    case .failure(let err):
                        print("Did fail to create 9GAG post with XML. \n Error: \(err.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            
            if self.elementName == "id" {
                self.postURL = data
            } else if self.elementName == "title" {
                self.title += data
            } else if self.elementName == "content" {
                do {
                    let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                    let matches = detector.matches(in: data, options: [], range: NSRange(location: 0, length: data.utf16.count))
                    
                    for match in matches {
                        guard let range = Range(match.range, in: data) else { continue }
                        let url = String(data[range])
                        if url.contains(".png") || url.contains(".jpg") {
                            let mediaTypeString = String(imageURL.suffix(3))
                            if let mediaType = MediaType(rawValue: mediaTypeString) {
                                NetworkManager.shared.fetchImageFor(post: Post(credit: .ninegag, creditDescription: "9GAG/meme", postURL: postURL, title: title.htmlDecoded, imageURL: url, mediaType: mediaType)) { (result) in
                                    switch result {
                                    case .success(let post):
                                        self.delegate?.didFinishFetching9GAG(post: post)
                                    case .failure(let err):
                                        print("Failed with error: \(err.localizedDescription)")
                                    }
                                }
                            }
                            break
                        }
                    }
                } catch {
                    print("Failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
}
