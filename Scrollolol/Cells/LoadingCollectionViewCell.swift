//
//  LoadingCollectionViewCell.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-09-01.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit
import Lottie

class LoadingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var insetContentView: UIView!
    let lottieView = AnimationView(name: "loading")
    
    
    class func getNib() -> UINib {
        return UINib(nibName: "LoadingCollectionViewCell", bundle: Bundle.main)
    }
    
    class func reuseIdentifier() -> String {
        return "LoadingCollectionViewCell"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLottieView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setupLottieView()
    }
    
    func setupLottieView() {
        lottieView.removeFromSuperview()
        lottieView.loopMode = .loop
        insetContentView.addSubview(lottieView)
        lottieView.constrainToEdgesOf(superview: insetContentView, padding: UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0))
        lottieView.play()
    }

}
