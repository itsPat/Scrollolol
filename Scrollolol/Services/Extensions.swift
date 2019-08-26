//
//  Extensions.swift
//  Scrollolol
//
//  Created by Patrick Trudel on 2019-08-24.
//  Copyright © 2019 Patrick Trudel. All rights reserved.
//

import UIKit

extension UIColor {
    static let monkeyOrange = UIColor(red: 255/255, green: 108/255, blue: 55/255, alpha: 1.0)
    static let monkeyGray = UIColor(red: 64/255, green: 79/255, blue: 87/255, alpha: 1.0)
    static let monkeyPurple = UIColor(red: 104/255, green: 62/255, blue: 234/255, alpha: 1.0)
    static let darkModeTableViewBackground = UIColor(red: 33/255, green: 33/255, blue: 36/255, alpha: 1.0)
    static let darkModeCellBackground = UIColor(red: 51/255, green: 53/255, blue: 58/255, alpha: 1.0)
}

extension UIView {
    func constrainToEdgesOf(superview: UIView, padding: UIEdgeInsets) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: superview, attribute: .left, multiplier: 1.0, constant: padding.left),
            NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: superview, attribute: .right, multiplier: 1.0, constant: -padding.right),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1.0, constant: padding.top),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: superview, attribute: .bottom, multiplier: 1.0, constant: -padding.bottom)
            ])
    }
    
    
    func setStandardShadow() {
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowRadius = 3.0
        layer.shadowOpacity = 0.3
        layer.masksToBounds = false
    }
}

extension String {
    var htmlDecoded: String {
        let decoded = try? NSAttributedString(data: Data(utf8), options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil).string
        
        return decoded ?? self
    }
}

extension CGPoint {
    mutating func getPointIn(direction: CGPoint, multiplier: CGFloat) -> CGPoint {
        let newX = x + (direction.x * multiplier)
        let newY = y + (direction.y * multiplier)
        self.x = newX
        self.y = newY
        return self
    }
}
