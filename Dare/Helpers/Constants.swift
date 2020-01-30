//
//  Constants.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/5/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import Foundation

struct Constants {
    
    struct Authentication {
        static let signUpEmailToPasswordSegue = "SignUpEmailToPasswordSegue"
        static let signUpEmailToAlreadySignedUpPassword = "SegueToEmailPasswordLogin"
        static let preRegPasswordToMain = "PreRegPasswordToMain"
        static let emailSignUpToMain = "EmailSignUpToMain"
        static let emailSignInToMain = "EmailSignInToMain"
        static let signUpToMain = "SignUpToMain"
        static let logInToMain = "LogInToMain"
    }
    
    struct Main {
        static let cameraToMain = "CameraToPostSegue"
        static let darePostToHome = "DarePostToHome"
    }
    
}
