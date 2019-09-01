//
//  ViewController.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-20.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    var posts = [Post]()
    var blurView: UIVisualEffectView?
    var fullScreenImageView: UIImageView?
    var currentModifier: SubredditModifier?
    var finalPage = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "starSmall"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(didTapStar(_:)), for: .touchUpInside)
        navigationItem.titleView = button
        toggleOverlayView(active: true)
        refreshControl.addTarget(self, action:  #selector(handleRefresh), for: .valueChanged)
        tableView.backgroundView = refreshControl
        tableView.scrollsToTop = true
        tableView.register(PostCell.getNib(), forCellReuseIdentifier: PostCell.reuseIdentifier())
        tableView.register(LoadingCell.getNib(), forCellReuseIdentifier: LoadingCell.reuseIdentifier())
        fetchPosts(modifier: .hot, after: false)
        NetworkManager.shared.fetch9GAGPosts(delegate: self)
    }
    
    func fetchPosts(modifier: SubredditModifier, after: Bool) {
        NetworkManager.shared.delegate = self
        NetworkManager.shared.fetchPosts(modifier: modifier, after: after)
    }
    
    // MARK: Actions
    @objc func handleRefresh() {
        fetchPosts(modifier: currentModifier ?? .hot, after: false)
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @objc func didTapStar(_ sender: UIButton) {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
    }
    
    @IBAction func didTapMenu(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func didTapFetch(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for modifier in SubredditModifier.allCases {
            let action = UIAlertAction(title: modifier.rawValue.capitalized, style: .default) { (_) in
                self.fetchPosts(modifier: modifier, after: false)
                self.currentModifier = modifier
            }
            actionSheet.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancel)
        
        definesPresentationContext = true
        actionSheet.popoverPresentationController?.barButtonItem = sender
        present(actionSheet, animated: true, completion: nil)
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
        
        guard let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return }
        let post = posts[indexPath.section]
        
        guard let image = PhotoManager.shared.loadMediaFor(post: post) else { return }
        
        if !UIAccessibility.isReduceTransparencyEnabled {
            let blurEffect = UIBlurEffect(style: .dark)
            blurView = UIVisualEffectView(effect: blurEffect)
            guard let blurView = blurView else { return }
            blurView.frame = self.view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.alpha = 0.0
            view.addSubview(blurView)
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
                blurView.alpha = 1.0
            }, completion: nil)
        }
        
        let rectOfCell = tableView.rectForRow(at: indexPath)
        let rectOfCellInSuperview = tableView.convert(rectOfCell, to: tableView.superview)
        let convertedImageViewRect = CGRect(x: rectOfCellInSuperview.origin.x + cell.postImageView.frame.origin.x, y: rectOfCellInSuperview.origin.y + cell.postImageView.frame.origin.y, width: cell.postImageView.frame.width, height: cell.postImageView.frame.height)
        
        fullScreenImageView = UIImageView(frame: convertedImageViewRect)
        fullScreenImageView?.contentMode = .scaleAspectFit
        fullScreenImageView?.backgroundColor = UIAccessibility.isReduceTransparencyEnabled ? .black : .clear
        fullScreenImageView?.image = image
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        fullScreenImageView?.addGestureRecognizer(panGesture)
        fullScreenImageView?.isUserInteractionEnabled = true
        guard let fullScreenImageView = fullScreenImageView else { return }
        view.addSubview(fullScreenImageView)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.fullScreenImageView?.frame = self.view.frame.inset(by: self.view.safeAreaInsets)
        }) { (_) in
            self.fullScreenImageView?.translatesAutoresizingMaskIntoConstraints = false
            self.fullScreenImageView?.constrainToEdgesOf(superview: self.view, padding: self.view.safeAreaInsets)
        }
    }
    
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count + (finalPage ? 0 : 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !posts.isEmpty else { return 100.0 }
        guard indexPath.section != posts.count else { return 100.0 }
        guard let ratio = posts[indexPath.section].getImageAspectRatio() else { return 100.0 }
        return (view.frame.width / ratio) + 108.25
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !posts.isEmpty else { return 100.0 }
        guard indexPath.section != posts.count else { return 100.0 }
        guard let ratio = posts[indexPath.section].getImageAspectRatio() else { return 100.0 }
        return (view.frame.width / ratio) + 108.25
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clearCell = UITableViewCell(style: .default, reuseIdentifier: nil)
        clearCell.backgroundColor = UIColor.clear
        clearCell.contentView.backgroundColor = UIColor.clear
        guard !posts.isEmpty else { return clearCell }
        if indexPath.section == posts.count, !finalPage {
            // Present Loading Cell until new posts are downloaded.
            fetchPosts(modifier: currentModifier ?? .hot, after: true)
            let cell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier()) as! LoadingCell
            return cell
        } else {
            // Present Post Cell once the image is available.
            let post = posts[indexPath.section]
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier()) as! PostCell
            cell.post = post
            cell.delegate = self
            cell.updateCell()
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func insertPost(post: Post) {
        DispatchQueue.main.async {
            self.toggleOverlayView(active: false)
            self.posts.append(post)
            self.tableView.insertSections(IndexSet(integer: self.posts.count - 1), with: .none) 
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openImageInFullScreen(indexPath: indexPath)
    }
}

extension ViewController: NetworkManagerDelegate {
    func fetchRedditPostDidFail() {
        print("❌REDDIT POST FAILED❌")
        DispatchQueue.main.async {
            self.finalPage = true
            self.tableView.reloadData()
        }
    }
    
    func didFinishFetchingReddit(post: Post) {
        insertPost(post: post)
    }
}

extension ViewController: XMLManagerDelegate {
    func didFinishFetching9GAG(post: Post) {
        insertPost(post: post)
    }
}



extension ViewController: PostCellDelegate { }

