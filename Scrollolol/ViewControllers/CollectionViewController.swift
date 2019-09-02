//
//  CollectionViewController.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-09-01.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

class CollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var modifierButton: UIButton!
    let refreshControl = UIRefreshControl()
    var posts = [Post]()
    var blurView: UIVisualEffectView?
    var fullScreenImageView: UIImageView?
    var currentModifier: SubredditModifier?
    var finalPage = false
    var existingImagePaths = [String:Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleOverlayView(active: true)
        refreshControl.addTarget(self, action:  #selector(handleRefresh), for: .valueChanged)
        collectionView.backgroundView = refreshControl
        collectionView.register(PostCollectionViewCell.getNib(), forCellWithReuseIdentifier: PostCollectionViewCell.reuseIdentifier())
        collectionView.register(LoadingCollectionViewCell.getNib(), forCellWithReuseIdentifier: LoadingCollectionViewCell.reuseIdentifier())
        fetchPosts(modifier: .hot, after: false)
    }
    
    func fetchPosts(modifier: SubredditModifier, after: Bool) {
        NetworkManager.shared.delegate = self
        NetworkManager.shared.fetchInstagramPosts(after: after)
        NetworkManager.shared.fetchRedditPosts(modifier: modifier, after: after)
//        NetworkManager.shared.fetch9GAGPosts(delegate: self)
    }
    
    // MARK: Actions
    @objc func handleRefresh() {
//        fetchPosts(modifier: currentModifier ?? .hot, after: false)
//        collectionView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @IBAction func didTapModifier(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.blurStyle = .dark
        actionSheet.view.tintColor = .yellow
        
        for modifier in SubredditModifier.allCases {
            let action = UIAlertAction(title: modifier.rawValue.capitalized, style: .default) { (_) in
                self.posts.removeAll()
                self.collectionView.reloadData()
                self.fetchPosts(modifier: modifier, after: false)
                self.currentModifier = modifier
                sender.setTitle(modifier.rawValue.uppercased(), for: .normal)
                sender.sizeToFit()
                sender.frame = sender.frame.insetBy(dx: -16, dy: 0)
            }
            actionSheet.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancel)
        
        definesPresentationContext = true
        actionSheet.popoverPresentationController?.sourceRect = sender.frame
        present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func didTapMenu(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func didTapFetch(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        guard let fullScreenImageView = self.fullScreenImageView else { return }
        switch sender.state {
        case .changed:
            let angleMultiplier = (fullScreenImageView.center.x - view.center.x) / (view.frame.maxX / 2)
            let angle: CGFloat = (10.0 * .pi / 180) * angleMultiplier
            fullScreenImageView.transform = CGAffineTransform(rotationAngle: angle)
            fullScreenImageView.center = CGPoint(x: self.view.center.x + translation.x, y: self.view.center.y + translation.y)
        case .ended:
            let distanceFromCenterX = (fullScreenImageView.center.x - view.center.x) / view.frame.maxX
            let distanceFromCenterY = (fullScreenImageView.center.y - view.center.y) / view.frame.maxY
            if abs(distanceFromCenterX) > 0.1 || abs(distanceFromCenterY) > 0.1 {
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                    fullScreenImageView.center = fullScreenImageView.center.getPointIn(direction: translation, multiplier: 3.0)
                    fullScreenImageView.alpha = 0.0
                    self.blurView?.alpha = 0.0
                }) { (_) in
                    self.fullScreenImageView?.removeFromSuperview()
                    self.blurView?.removeFromSuperview()
                }
            } else {
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveLinear, animations: {
                    fullScreenImageView.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
                    fullScreenImageView.transform = CGAffineTransform(rotationAngle: 0)
                }, completion: nil)
            }
        default:
            break
        }
    }
    
    
    
    func toggleOverlayView(active: Bool) {
        let currentWindow: UIWindow? = UIApplication.shared.keyWindow
        if active {
            let overlay = OverlayView.instanceFromNib()
            overlay.frame = view.frame
            overlay.tag = 420
            currentWindow?.addSubview(overlay)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: {
                currentWindow?.viewWithTag(420)?.alpha = 0.0
            }) { (_) in
                currentWindow?.viewWithTag(420)?.removeFromSuperview()
            }
        }
    }
    
    func openImageInFullScreen(indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PostCollectionViewCell else { return }
        guard let image = cell.postImageView.image else { return }
        
        if !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .dark)
            self.blurView = UIVisualEffectView(effect: blurEffect)
            guard let blurView = self.blurView else { return }
            blurView.frame = self.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.alpha = 0.0
            self.view.addSubview(blurView)
            
            
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                blurView.alpha = 1.0
            }, completion: nil)
        }
        
        let rectOfCellInSuperview = self.collectionView.convert(cell.frame, to: self.collectionView.superview)
        let convertedImageViewRect = CGRect(x: rectOfCellInSuperview.origin.x + cell.postImageView.frame.origin.x, y: rectOfCellInSuperview.origin.y + cell.postImageView.frame.origin.y, width: cell.postImageView.frame.width, height: cell.postImageView.frame.height)
        
        self.fullScreenImageView = UIImageView(frame: convertedImageViewRect)
        self.fullScreenImageView?.contentMode = .scaleAspectFit
        self.fullScreenImageView?.backgroundColor = UIAccessibility.isReduceTransparencyEnabled ? .black : .clear
        self.fullScreenImageView?.image = image
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.fullScreenImageView?.addGestureRecognizer(panGesture)
        self.fullScreenImageView?.isUserInteractionEnabled = true
        guard let fullScreenImageView = self.fullScreenImageView else { return }
        DispatchQueue.main.async {
            self.view.addSubview(fullScreenImageView)
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.fullScreenImageView?.frame = self.view.frame.inset(by: self.view.safeAreaInsets)
            }) { (_) in
                self.fullScreenImageView?.translatesAutoresizingMaskIntoConstraints = false
                self.fullScreenImageView?.constrainToEdgesOf(superview: self.view, padding: self.view.safeAreaInsets)
            }
        }
    }
    
    

}

extension CollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count + (finalPage ? 0 : 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == posts.count && !finalPage || posts.isEmpty {
            // Present Loading Cell until new posts are downloaded.
            fetchPosts(modifier: currentModifier ?? .hot, after: true)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCollectionViewCell.reuseIdentifier(), for: indexPath) as! LoadingCollectionViewCell
            return cell
        } else {
            // Present Post Cell once the image is available.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCollectionViewCell.reuseIdentifier(), for: indexPath) as! PostCollectionViewCell
            let post = posts[indexPath.item]
            cell.updateCell(post: post)
            cell.delegate = self
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func insertPost(post: Post) {
        guard let imagePath = post.imagePath else { return }
        DispatchQueue.main.async {
            if self.existingImagePaths[imagePath] == nil {
                self.existingImagePaths[imagePath] = true
                print("⭐️DID FETCH POST FROM \(post.credit.rawValue.uppercased())⭐️")
                self.toggleOverlayView(active: false)
                self.posts.append(post)
                self.collectionView.insertItems(at: [IndexPath(item: self.posts.count - 1, section: 0)])
            }
        }
    }
    
}

extension CollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        openImageInFullScreen(indexPath: indexPath)
    }
}

extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let loadingCellSize = CGSize(width: view.frame.width, height: 140)
        guard !posts.isEmpty else { return loadingCellSize }
        guard indexPath.item != posts.count else { return loadingCellSize }
        guard let ratio = posts[indexPath.item].imageAspectRatio else { return .zero }
        let numberOfCellsHorizontally: CGFloat = UIDevice().userInterfaceIdiom == .pad ? 3 : 1
        let spacing = numberOfCellsHorizontally * 8.0 * (numberOfCellsHorizontally + 1)
        let width = (view.frame.inset(by: view.safeAreaInsets).width - spacing) / numberOfCellsHorizontally
        let height = (width / ratio) + 112
        return CGSize(width: width, height: height)
    }
}


extension CollectionViewController: NetworkManagerDelegate {
    func fetchPostDidFail() {
        print("❌FETCH POST FAILED❌")
        DispatchQueue.main.async {
            self.finalPage = true
            self.collectionView.reloadData()
        }
    }
    
    func didFinishFetching(post: Post) {
        insertPost(post: post)
    }
}

extension CollectionViewController: XMLManagerDelegate {
    func didFinishFetching9GAG(post: Post) {
        insertPost(post: post)
    }
}



extension CollectionViewController: PostCellDelegate { }


