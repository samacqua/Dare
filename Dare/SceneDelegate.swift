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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
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

