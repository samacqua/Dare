//
//  HalfModalPresentationController.swift
//  Dare
//
//  Created by Sam Acquaviva on 1/6/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

// based on https://github.com/martinnormark/HalfModalPresentationController

import UIKit

enum ModalScaleState {
    case adjustedOnce
    case normal
}

class HalfModalPresentationController : UIPresentationController {
    var isMaximized: Bool = false
    
    var panGestureRecognizer: UIPanGestureRecognizer
    var direction: CGFloat = 0
    var state: ModalScaleState = .normal
    var dimmingView: UIView! {
        guard let container = containerView else { return nil }
        
        let view = UIView(frame: container.bounds)
        view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)))
        )
        view.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        return view
    }
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        self.panGestureRecognizer = UIPanGestureRecognizer()
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        panGestureRecognizer.addTarget(self, action: #selector(onPan(pan:)))
        presentedViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func didTap(tap: UITapGestureRecognizer) {
            self.presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    @objc func onPan(pan: UIPanGestureRecognizer) -> Void {
        let endPoint = pan.translation(in: pan.view?.superview)
        
        switch pan.state {
        case .began:
            presentedView!.frame.size.height = containerView!.frame.height
        case .changed:
            let velocity = pan.velocity(in: pan.view?.superview)
            switch state {
            case .normal:
                presentedView!.frame.origin.y = endPoint.y + containerView!.frame.height / 2
            case .adjustedOnce:
                presentedView!.frame.origin.y = endPoint.y
            }
            direction = velocity.y
            
            break
        case .ended:
            if direction < 0 {
                changeScale(to: .adjustedOnce)      // maximize if swiping up
            } else {
                if state == .adjustedOnce {     // if maximized, bring down to normal
                    changeScale(to: .normal)
                } else {    // else, dismiss
                    self.presentedViewController.dismiss(animated: true, completion: nil)
                }
            }
        default:
            break
        }
    }
    
    func changeScale(to state: ModalScaleState) {
        if let presentedView = presentedView, let containerView = self.containerView {
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10.0, options: .curveEaseInOut, animations: { () -> Void in
                presentedView.frame = containerView.frame
                let containerFrame = containerView.frame
                let halfFrame = CGRect(origin: CGPoint(x: 0, y: containerFrame.height / 2),
                                       size: CGSize(width: containerFrame.width, height: containerFrame.height / 2))
                let frame = state == .adjustedOnce ? containerView.frame : halfFrame
                
                presentedView.frame = frame
                
                if let navController = self.presentedViewController as? UINavigationController {
                    self.isMaximized = true
                    
                    navController.setNeedsStatusBarAppearanceUpdate()
                    
                    // Force the navigation bar to update its size
                    navController.isNavigationBarHidden = true
                    navController.isNavigationBarHidden = false
                }
            }, completion: { (isFinished) in
                self.state = state
            })
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0, y: containerView!.bounds.height - containerView!.bounds.height / 2.5, width: containerView!.bounds.width, height: containerView!.bounds.height / 2.5)
    }
    
    override func presentationTransitionWillBegin() {
        let dimmedView = dimmingView
        
        if let containerView = self.containerView, let coordinator = presentingViewController.transitionCoordinator {
            dimmedView!.alpha = 0
            containerView.addSubview(dimmedView!)
            dimmedView!.addSubview(presentedViewController.view)
            
            coordinator.animate(alongsideTransition: { (context) -> Void in
                dimmedView!.alpha = 1.0
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { (context) -> Void in
                self.dimmingView.alpha = 0
                self.presentingViewController.view.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
            isMaximized = false
        }
    }
}

protocol HalfModalPresentable { }

extension HalfModalPresentable where Self: UIViewController {
    func maximizeToFullScreen() -> Void {
        if let presentation = navigationController?.presentationController as? HalfModalPresentationController {
            presentation.changeScale(to: .adjustedOnce)
        }
    }
}

extension HalfModalPresentable where Self: UINavigationController {
    func isHalfModalMaximized() -> Bool {
        if let presentationController = presentationController as? HalfModalPresentationController {
            return presentationController.isMaximized
        }
        return false
    }
}
