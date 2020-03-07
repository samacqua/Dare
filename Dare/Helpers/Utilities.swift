//
//  Utilities.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import AVFoundation

class Utilities {
    
    // Style UI Elements
    
    static func returnColor() -> UIColor {
        let themeColor = UIColor.init(red: 245/255, green: 135/255, blue: 66/255, alpha: 1)
        return themeColor
    }
    
    static func styleTextField(_ textfield:UITextField) {
        
        // Create the bottom line
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: textfield.frame.height - 2, width: textfield.frame.width, height: 2)
        bottomLine.backgroundColor = Utilities.returnColor().cgColor
        
        // Remove border on text field
        textfield.borderStyle = .none
        
        // Add the line to the text field
        textfield.layer.addSublayer(bottomLine)
        
    }
    
    static func styleFilledButton(_ button:UIButton) {
        
        // Filled rounded corner style
        button.backgroundColor = returnColor()
        button.layer.cornerRadius = 10
        button.tintColor = UIColor.white
    }
    
    static func styleFilledBarButtonItem(_ button:UIBarButtonItem) {
        button.tintColor = returnColor()
    }
    
    static func styleFilledLabel(_ label: UILabel) {
        label.backgroundColor = returnColor()
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.tintColor = UIColor.white
    }
    
    static func styleHollowButton(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 10
        button.tintColor = UIColor.white
    }
    
    static func styleHollowButtonColored(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.orange.cgColor
        button.layer.cornerRadius = 10
        button.tintColor = UIColor.orange
    }
    
    // Validate user input
    
    static func isPasswordValid(_ password : String?) -> Bool {
        guard password != nil else { return false }
        let regEx = "^((?!\\s).){8,}$"
        
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return passwordTest.evaluate(with: password)
    }
    
    static func isEmailValid(_ email : String?) -> Bool {
        guard email != nil else { return false }
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return emailTest.evaluate(with: email)
    }
    
    static func isUsernameValid(_ username : String?) -> Bool {
        guard username != nil else { return false }
        let regEx = "[a-zA-Z0-9_]{1,15}"
        let usernameTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return usernameTest.evaluate(with: username)
    }
    
    // Save/load image locally
    
    static func saveImage(imageName: String, image: UIImage, completion: @escaping(_ error: Error?) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                return completion(removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            return completion(error)
        }
        return completion(nil)
    }
    
    static func loadImageFromDiskWith(fileName: String) -> UIImage? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        
        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image
        }
        return nil
    }
    
    // Create video thumbnail
    
    static func createThumbnail(url: URL) -> UIImage? {
        do {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil  // when calling func, if image == nil, show error
        }
    }


// Create NSAttributes

    private static let defaultShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = CGSize(width: 0, height: 0)
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
        return shadow
    }()
    
    static func createAttributes(color: UIColor, font: UIFont, shadow: Bool) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor : color,
            .font : font
        ]
        if shadow {
            attributes[.shadow] = defaultShadow
        }
        return attributes
    }
}
