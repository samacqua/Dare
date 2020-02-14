//
//  Utilities.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation
import UIKit

class Utilities {
    
    
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
        button.layer.cornerRadius = button.frame.size.height / 2
        button.tintColor = UIColor.white
    }
    
    static func styleFilledBarButtonItem(_ button:UIBarButtonItem) {
        button.tintColor = returnColor()
    }
    
    static func styleFilledLabel(_ label: UILabel) {
        label.backgroundColor = returnColor()
        label.layer.cornerRadius = label.frame.size.height / 2
        label.layer.masksToBounds = true
        label.tintColor = UIColor.white
    }
    
    static func styleHollowButton(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = button.frame.size.height / 2
        button.tintColor = UIColor.white
    }
    
    static func styleHollowButtonColored(_ button:UIButton) {
        
        // Hollow rounded corner style
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.orange.cgColor
        button.layer.cornerRadius = button.frame.size.height / 2
        button.tintColor = UIColor.orange
    }
    
    
    static func isPasswordValid(_ password : String?) -> Bool {
        guard password != nil else { return false }
        let regEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return passwordTest.evaluate(with: password)
    }
    
    static func isPhoneNumberValid(_ phoneNumber : String?) -> Bool {
        guard phoneNumber != nil else { return false }
        let regEx = "^[0-9]{9,10}"
        let phoneNumberTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return phoneNumberTest.evaluate(with: phoneNumber)
    }
    
    static func isEmailValid(_ email : String?) -> Bool {
        guard email != nil else { return false }
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return emailTest.evaluate(with: email)
    }
    
    static func isUsernameValid(_ username : String?) -> Bool {
        guard username != nil else { return false }
        let regEx = "[a-z0-9A-Z]{1,15}"
        let usernameTest = NSPredicate(format: "SELF MATCHES %@", regEx)
        return usernameTest.evaluate(with: username)
    }
    
    static func saveImage(imageName: String, image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = imageName
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed old image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
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
}
