//
//  PostCell.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-20.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

protocol PostCellDelegate: UIViewController { }


class PostCell: UITableViewCell {

    @IBOutlet weak var sourceButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postCreditDescription: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    var post: Post?
    var delegate: PostCellDelegate?
    
    class func getNib() -> UINib {
        return UINib(nibName: "PostCell", bundle: Bundle.main)
    }
    
    class func reuseIdentifier() -> String {
        return "PostCell"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        postTitle.text = nil
        postImageView.image = nil
    }
    
    func updateCell() {
        guard let post = post else { return }
        sourceButton.setImage(post.credit == .reddit ? #imageLiteral(resourceName: "reddit") : #imageLiteral(resourceName: "9gag"), for: .normal)
        postTitle.text = post.title
        postCreditDescription.text = post.creditDescription
        switch post.mediaType {
        case .gif:
            postImageView.image = UIImage.gifImageWithData(post.imageData ?? Data())
        default:
            postImageView.image = UIImage(data: post.imageData ?? Data())
        }
    }
    
    @IBAction func didTapSource(_ sender: Any) {
        guard let postURL = URL(string: post?.postURL ?? "") else { return }
        UIApplication.shared.open(postURL, options: [:], completionHandler: nil)
    }
    
    @IBAction func didTapShare(_ sender: Any) {
        guard let post = post else { return }
        guard let image = UIImage(data: post.imageData ?? Data()) else { return }
        let activityItems: [Any] = [image, "Check out this post I found on Meme Monkey!"]
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        delegate?.present(avc, animated: true, completion: nil)
    }
    
}
