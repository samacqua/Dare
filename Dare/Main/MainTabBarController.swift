//
//  MainTabBarController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/8/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit
import FirebaseStorage  // necessary to transfer completion info

class MainTabBarController: UITabBarController {
    
    let homeVC = HomeViewController()
    var uploadTask: StorageUploadTask?
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        UITabBar.appearance().tintColor = .white
        let tabBarColor = UIColor(white: 0.0, alpha: 1.0)
        UITabBar.appearance().barTintColor = tabBarColor
        
        let offset: CGFloat = 6.0
        

        let homeTabBarImageUnselected = UIImage(named: "home_unselected")
        let homeTabBarImageSelected = UIImage(named: "home_selected")
        homeVC.tabBarItem = UITabBarItem(title: nil, image: homeTabBarImageUnselected, selectedImage: homeTabBarImageSelected)
        homeVC.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
        homeVC.tabBarItem.tag = 0
        
        let exploreVC = ExploreViewController()
        let exploreTabBarImageUnselected = UIImage(named: "search_unselected")
        let exploreTabBarImageSelected = UIImage(named: "search_selected")
        exploreVC.tabBarItem = UITabBarItem(title: nil, image: exploreTabBarImageUnselected, selectedImage: exploreTabBarImageSelected)
        exploreVC.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
        exploreVC.tabBarItem.tag = 1
        
        let postVC = CreateScrollViewController()
        let postTabBarImage = UIImage(named: "dare_tabbar_item")
        postVC.tabBarItem = UITabBarItem(title: nil, image: postTabBarImage, tag: 2)
        postVC.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)

        let activityVC = ActivityViewController()
        let activityTabBarImageUnselected = UIImage(named: "activity_unselected")
        let activityTabBarImageSelected = UIImage(named: "activity_selected")
        activityVC.tabBarItem = UITabBarItem(title: nil, image: activityTabBarImageUnselected, selectedImage: activityTabBarImageSelected)
        activityVC.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
        activityVC.tabBarItem.tag = 3
        
        let profileVC = ProfileViewController()
        let profileTabBarImageUnselected = UIImage(named: "profile_unselected")
        let profileTabBarImageSelected = UIImage(named: "profile_selected")
        profileVC.tabBarItem = UITabBarItem(title: nil, image: profileTabBarImageUnselected, selectedImage: profileTabBarImageSelected)
        profileVC.tabBarItem.imageInsets = UIEdgeInsets(top: offset, left: 0, bottom: -offset, right: 0)
        profileVC.tabBarItem.tag = 4
        
        let viewControllerList = [homeVC, exploreVC, postVC, activityVC, profileVC]
        viewControllers = viewControllerList.map { UINavigationController(rootViewController: $0) }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if uploadTask != nil {
            homeVC.uploadTask = uploadTask
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {    // allows custom transition to create VC

    /*
     Called to allow the delegate to return a UIViewControllerAnimatedTransitioning delegate object for use during a noninteractive tab bar view controller transition.
     ref: https://developer.apple.com/documentation/uikit/uitabbarcontrollerdelegate/1621167-tabbarcontroller
     */
    
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if toVC.tabBarItem.tag == 2 {
            return TabBarAnimatedTransitioning()
        }
        return nil
    }
}

final class TabBarAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let destination = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }

        destination.alpha = 0.0
        destination.transform = .init(scaleX: 1.5, y: 1.5)
        transitionContext.containerView.addSubview(destination)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            destination.alpha = 1.0
            destination.transform = .identity
        }, completion: { transitionContext.completeTransition($0) })
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

}
