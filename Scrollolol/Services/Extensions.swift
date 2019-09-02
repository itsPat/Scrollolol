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
    static let darkModeTableViewBackground = UIColor(red: 48/255, green: 48/255, blue: 58/255, alpha: 1.0)
    static let darkModeCellBackground = UIColor.black
}

extension UIAlertController {
    
    private struct AssociatedKeys {
        static var blurStyleKey = "UIAlertController.blurStyleKey"
    }
    
    public var blurStyle: UIBlurEffect.Style {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.blurStyleKey) as? UIBlurEffect.Style ?? .extraLight
        } set (style) {
            objc_setAssociatedObject(self, &AssociatedKeys.blurStyleKey, style, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }
    
    public var cancelButtonColor: UIColor? {
        return blurStyle == .dark ? UIColor(red: 28.0/255.0, green: 28.0/255.0, blue: 28.0/255.0, alpha: 1.0) : nil
    }
    
    private var visualEffectView: UIVisualEffectView? {
        if let presentationController = presentationController, presentationController.responds(to: Selector(("popoverView"))), let view = presentationController.value(forKey: "popoverView") as? UIView // We're on an iPad and visual effect view is in a different place.
        {
            return view.recursiveSubviews.compactMap({$0 as? UIVisualEffectView}).first
        }
        
        return view.recursiveSubviews.compactMap({$0 as? UIVisualEffectView}).first
    }
    
    private var cancelActionView: UIView? {
        return view.recursiveSubviews.compactMap({
            $0 as? UILabel}
            ).first(where: {
                $0.text == actions.first(where: { $0.style == .cancel })?.title
            })?.superview?.superview
    }
    
    public convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, blurStyle: UIBlurEffect.Style) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.blurStyle = blurStyle
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        visualEffectView?.effect = UIBlurEffect(style: blurStyle)
        cancelActionView?.backgroundColor = cancelButtonColor
    }
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
    
    var recursiveSubviews: [UIView] {
        var subviews = self.subviews.compactMap({$0})
        subviews.forEach { subviews.append(contentsOf: $0.recursiveSubviews) }
        return subviews
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

extension UIImage {
    
    public class func gifImageWithData(_ data: Data, completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.global(qos: .background).async {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                print("image doesn't exist")
                completion(nil)
                return
            }
            completion(UIImage.animatedImageWithSource(source))
        }
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.06
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a ?? 0 < b ?? 0 {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
}

