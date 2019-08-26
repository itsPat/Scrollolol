//
//  OverlayView.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-25.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

class OverlayView: UIView {
    
    class func instanceFromNib() -> OverlayView {
        return UINib(nibName: "OverlayView", bundle: .main).instantiate(withOwner: self, options: nil).first as! OverlayView
    }

}
