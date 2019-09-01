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
    
    func saveMediaFor(post: Post, data: Data) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileName = "\(post.id).\(post.mediaType.rawValue)"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
        } catch {
            print("error saving file:", error)
        }
    }
    
    
    func loadMediaFor(post : Post) -> UIImage? {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(post.id).\(post.mediaType.rawValue)")
            switch post.mediaType {
            case .gif:
                do {
                    let data = try Data(contentsOf: imageURL)
                    return UIImage.gifImageWithData(data)
                } catch {
                    print(error.localizedDescription)
                    return nil
                }
            case .jpg, .png:
                return UIImage(contentsOfFile: imageURL.path)
            default:
                break
            }
        }
        return nil
    }
    
    func clearAllFilesFromTempDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            for path in directoryContents {
                let fullPath = documentsDirectory.appendingPathComponent(path).path
                let attributes = try FileManager.default.attributesOfItem(atPath: fullPath)
                if let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
                    let difference = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day,
                    abs(difference) >= 3 {
                    try FileManager.default.removeItem(atPath: fullPath)
                }
            }
        } catch {
            print("ERROR clearAllFilesFromTempDirectory() : \(error)")
        }
    }
    
    
}
