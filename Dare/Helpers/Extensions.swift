//
//  SegmentedControlExtension.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/2/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

extension UISegmentedControl{
    func removeBorder(){
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: self.bounds.size)
        self.setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
        self.setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)
        
        let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.white.cgColor, andSize: CGSize(width: 1.0, height: self.bounds.size.height))
        self.setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.orange, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)], for: .selected)
    }
    
    func addUnderlineForSelectedSegment(){
        removeBorder()
        let underlineWidth: CGFloat = self.bounds.size.width / CGFloat(self.numberOfSegments)
        let underlineHeight: CGFloat = 1.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = self.bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor.orange
        underline.tag = 1
        underline.layer.zPosition = 1
        self.addSubview(underline)
    }
    
    func changeUnderlinePosition(){
        guard let underline = self.viewWithTag(1) else {return}
        underline.layer.zPosition = 1
        let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
        UIView.animate(withDuration: 0.2, animations: {
            underline.frame.origin.x = underlineFinalXPosition
        })
    }
}

extension UIImage{
    
    class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        graphicsContext?.fill(rectangle)
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        let year = 52 * week
        
        if secondsAgo < minute {
            if secondsAgo < 15 {
                return "just now"
            }
            return "\(secondsAgo) seconds ago"
        } else if secondsAgo < hour {
            if Int(secondsAgo / minute) == 1 {
                return "1 minute ago"
            }
            return "\(Int(secondsAgo / minute)) minutes ago"
        } else if secondsAgo < day {
            if Int(secondsAgo / hour) == 1 {
                return "1 hour ago"
            }
            return "\(Int(secondsAgo / hour)) hours ago"
        } else if secondsAgo < week {
            if Int(secondsAgo / day) == 1 {
                return "1 day ago"
            }
            return "\(Int(secondsAgo / day)) days ago"
        } else if secondsAgo < year {
            if Int(secondsAgo / week) == 1 {
                return "1 week ago"
            }
            return "\(Int(secondsAgo / week)) weeks ago"
        }
        if Int(secondsAgo / year) == 1 {
            return "1 year ago"
        }
        return "\(Int(secondsAgo / year)) years ago"
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

extension UIView {
    
    func addConstraintsWithFormat(format: String, views: UIView...) {
        
        var viewsDict = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDict["v\(index)"] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDict))
    }
}

// Class to allow for padding on UILabel even when using autolayout. From https://stackoverflow.com/a/58876988/5416200
class UILabelPadded: UILabel {
    let UIEI = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    
    override var intrinsicContentSize:CGSize {
        numberOfLines = 0
        var s = super.intrinsicContentSize
        s.height = s.height + UIEI.top + UIEI.bottom
        s.width = s.width + UIEI.left + UIEI.right
        return s
    }
    
    override func drawText(in rect:CGRect) {
        let r = rect.inset(by: UIEI)
        super.drawText(in: r)
    }
    
    override func textRect(forBounds bounds:CGRect, limitedToNumberOfLines n:Int) -> CGRect {
        let b = bounds
        let tr = b.inset(by: UIEI)
        let ctr = super.textRect(forBounds: tr, limitedToNumberOfLines: 0)
        return ctr
    }
}

extension UIView {
    
    func showToast(message : String) {
        
        let toastLabel = UILabelPadded()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 18)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 10),
            toastLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            toastLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            toastLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
        
        UIView.animate(withDuration: 2.0, delay: 1.5, options: .curveEaseInOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }
