//
//  PhotoManager.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-09-01.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

class PhotoManager: NSObject {
    static let shared = PhotoManager()
    
    func saveMediaFor(post: Post, data: Data, completion: @escaping (Result<URL,Error>) -> ()) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let fileName = "\(post.id).\(post.mediaType.rawValue)"
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: imageURL.path) {
                DispatchQueue.global(qos: .background).async {
                    do {
                        try data.write(to: imageURL)
                        completion(.success(imageURL))
                    } catch {
                        print("error saving file:", error)
                        completion(.failure(error))
                    }
                }
            } else {
                completion(.success(imageURL))
            }
        }
    }
    
    
    func loadMediaFor(post : Post, completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.global(qos: .background).async {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(post.id).\(post.mediaType.rawValue)")
                switch post.mediaType {
                case .gif:
                    do {
                        let data = try Data(contentsOf: imageURL)
                        UIImage.gifImageWithData(data, completion: { (image) in
                            if let image = image {
                                completion(image)
                            }
                        })
                    } catch {
                        print(error.localizedDescription)
                    }
                case .jpeg, .jpg, .png:
                    completion(UIImage(contentsOfFile: imageURL.path))
                }
            }
        }
    }
    
    func clearFilesOlderThan(days: Int) {
        DispatchQueue.global(qos: .background).async {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            do {
                let directoryContents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
                for path in directoryContents {
                    let fullPath = documentsDirectory.appendingPathComponent(path).path
                    let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
                    if let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
                        let difference = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day,
                        abs(difference) >= days {
                        try FileManager.default.removeItem(atPath: fullPath)
                    } else {
                        print("File is younger than \(days) days.")
                    }
                }
                
                
            } catch {
                print("ERROR clearAllFilesFromTempDirectory() : \(error)")
            }
        }
    }
    
    
}
