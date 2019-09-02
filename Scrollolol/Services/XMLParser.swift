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
    var content = ""
    
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
            content = ""
        }
        self.elementName = elementName
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "entry" {
            do {
                let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
                for match in matches {
                    guard let range = Range(match.range, in: content) else { continue }
                    let url = String(content[range])
                    if let mediaType = MediaType(rawValue: imageURL.components(separatedBy: .punctuationCharacters).last ?? "") {
                        NetworkManager.shared.fetchImageFor(post: Post(id: postID, credit: .ninegag, creditDescription: "9GAG/meme", postURL: url, title: title.htmlDecoded, imageURL: url, mediaType: mediaType)) { (result) in
                            switch result {
                            case .success(let post):
                                self.delegate?.didFinishFetching9GAG(post: post)
                            case .failure(let err):
                                print("Failed with error: \(err.localizedDescription)")
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
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            
            if self.elementName == "id" {
                self.postURL = data
            } else if self.elementName == "title" {
                self.title += data
            } else if self.elementName == "content" {
                self.content += data
            }
        }
    }
}
