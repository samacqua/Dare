//
//  SceneDelegate.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/29/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Firebase

import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        print("Current user:", Auth.auth().currentUser ?? "No current user")

        guard let windowScene = (scene as? UIWindowScene) else {return}
        window = UIWindow(windowScene: windowScene)
        window?.tintColor = .black
        window?.windowScene = windowScene
        let startViewController = StartViewController()
        if Auth.auth().currentUser == nil {
            let navigationController = UINavigationController()
            navigationController.viewControllers = [startViewController]
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
        } else {
            print("Current user:", Auth.auth().currentUser!)
            let homeViewController = MainTabBarController()
            window?.rootViewController = homeViewController
            window?.makeKeyAndVisible()
        }
        
        // Google Sign-in Setup
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
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
            guard let uid = result?.user.uid else { return }
            if result!.additionalUserInfo!.isNewUser == true {
                let database = Firestore.firestore()
                let fullName = user.profile.name
                let username = (user.profile.name!).replacingOccurrences(of: " ", with: "").lowercased()
                let firstName = user.profile.givenName
                let lastName = user.profile.familyName
                let email = user.profile.email
                database.collection("users").document(uid).setData(["username": username, "email": email!, "uid": result!.user.uid, "full_name": fullName!, "first_name": firstName!, "last_name": lastName!])
                database.collection("usernames").document(username).setData(["email": email!])
            }
            if Auth.auth().currentUser == nil {
                let navigationController = UINavigationController()
                let viewController = StartViewController()
                navigationController.viewControllers = [viewController]
                self.window?.rootViewController = navigationController
            } else {
                let viewController = MainTabBarController()
                self.window?.rootViewController = viewController
            }
            self.window?.makeKeyAndVisible()
            print("Signed in w google in scene delegate. current user:", Auth.auth().currentUser?.uid ?? "None")
        }
    }
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        let _ = ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation])
    }
}

