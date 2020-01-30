//
//  AppDelegate.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/29/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase
import FirebaseFirestore
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase Setup
        FirebaseApp.configure()
        
        // Facebook SDK Setup
        if #available(iOS 13.0, *) {    } else {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.makeKeyAndVisible()
            
            if Auth.auth().currentUser == nil {
                let viewController = StartViewController()
                window?.rootViewController = viewController
            } else {
                let viewController = MainTabBarController()
                window?.rootViewController = viewController
            }
        }
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        // Google Sign-in Setup
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if error != nil {
            print("Error logging into google: ", error!)
        return
      }
      guard let authentication = user.authentication else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (result, err) in
            if err != nil {
                print("Error signing into firebase after google login: ", err!)
                return
            }
            if let uid = result?.user.uid {
                let database = Firestore.firestore()
                let fullName = user.profile.name
                let username = (user.profile.name!).replacingOccurrences(of: " ", with: "").lowercased()
                let firstName = user.profile.givenName
                let lastName = user.profile.familyName
                let email = user.profile.email
                database.collection("users").document(uid).setData(["username": username, "email": email!, "uid": result!.user.uid, "full_name": fullName!, "first_name": firstName!, "last_name": lastName!])
                database.collection("usernames").document(username).setData(["email": email!])
            }
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
        let handled = ApplicationDelegate.shared.application(application, open: url, options: options)
        GIDSignIn.sharedInstance()?.handle(url)
        return handled
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

