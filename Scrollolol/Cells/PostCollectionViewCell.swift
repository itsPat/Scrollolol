//
//  PostCollectionViewCell.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-09-01.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

protocol PostCellDelegate: UIViewController { }

class PostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var sourceButton: UIButton!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postCreditDescription: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    var post: Post?
    var delegate: PostCellDelegate?
    
    
    class func getNib() -> UINib {
        return UINib(nibName: "PostCollectionViewCell", bundle: Bundle.main)
    }
    
    class func reuseIdentifier() -> String {
        return "PostCollectionViewCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postTitle.text = nil
        postImageView.image = nil
    }
    
    func updateCell(post: Post) {
        self.post = post
        guard let post = self.post else { return }
        switch post.credit {
        case .instagram:
            sourceButton.setImage(#imageLiteral(resourceName: "instagram"), for: .normal)
        case .reddit:
            sourceButton.setImage(#imageLiteral(resourceName: "reddit"), for: .normal)
        case .ninegag:
            sourceButton.setImage(#imageLiteral(resourceName: "9gag"), for: .normal)
        default:
            break
        }
        postTitle.text = post.title
        postCreditDescription.text = post.creditDescription
        PhotoManager.shared.loadMediaFor(post: post) { (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self.postImageView.image = image
                }
            }
        }
    }
    
    @IBAction func didTapSource(_ sender: Any) {
        guard let postURL = URL(string: post?.postURL ?? "") else { return }
        UIApplication.shared.open(postURL, options: [:], completionHandler: nil)
    }
    
    @IBAction func didTapStar(_ sender: Any) {
        
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        
    }
    
    @IBAction func didTapShare(_ sender: Any) {
        guard let image = postImageView.image else { return }
        let activityItems: [Any] = [image, "Sent via ⭐️ Meme Star ⭐️"]
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        DispatchQueue.main.async {
            self.delegate?.present(avc, animated: true, completion: nil)
        }
    }

}
