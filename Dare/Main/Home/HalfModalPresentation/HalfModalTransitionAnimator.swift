//
//  HalfModalTransitionAnimator.swift
//  Dare
//
//  Created by Sam Acquaviva on 2/11/20.
//  Copyright © 2020 Sam Acquaviva. All rights reserved.
//

import UIKit

class HalfModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var type: HalfModalTransitionAnimatorType
    
    init(type:HalfModalTransitionAnimatorType) {
        self.type = type
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                from!.view.transform = CGAffineTransform(translationX: 0, y: from!.view.frame.height)
                
            }) { (completed) in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }

    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
}

internal enum HalfModalTransitionAnimatorType {     // when calling UIViewControllerAnimatedTransitioning, must explicitly say type hence why single enum is necessary
    case Dismiss
}
