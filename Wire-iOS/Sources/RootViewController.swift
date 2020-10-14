//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit

final class RootViewController: UIViewController {
    private var childViewController: UIViewController?
    
    override var childForStatusBarStyle: UIViewController? {
        return childViewController
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return childViewController
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func set(childViewController newViewController: UIViewController?,
             animated: Bool = false,
             completion: (() -> Void)? = nil) {
        if let newViewController = newViewController, let previousViewController = childViewController {
            transition(
                from: previousViewController,
                to: newViewController,
                animated: animated,
                completion: completion)
        } else if let newViewController = newViewController {
            contain(newViewController, completion: completion)
        } else {
            removeChildViewController(animated: animated, completion: completion)
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func contain(_ newViewController: UIViewController, completion: (() -> Void)?) {
        add(newViewController)
        newViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newViewController.view.frame = view.bounds
        view.addSubview(newViewController.view)
        newViewController.didMove(toParent: self)
        childViewController = newViewController
        completion?()
    }
    
    private func removeChildViewController(animated: Bool, completion: (() -> Void)?) {
        let animationGroup = DispatchGroup()
        if childViewController?.presentedViewController != nil {
            animationGroup.enter()
            childViewController?.dismiss(animated: animated) {
                animationGroup.leave()
            }
        }
        
        childViewController?.willMove(toParent: nil)
        childViewController?.view.removeFromSuperview()
        childViewController?.removeFromParent()
        childViewController = nil
        
        animationGroup.notify(queue: .main) {
            completion?()
        }
    }
    
    private func transition(from fromViewController: UIViewController,
                            to toViewController: UIViewController,
                            animated: Bool = false,
                            completion: (() -> Void)?) {
        let animationGroup = DispatchGroup()
        
        if fromViewController.presentedViewController != nil {
            animationGroup.enter()
            fromViewController.dismiss(animated: animated) {
                animationGroup.leave()
            }
        }
        
        fromViewController.willMove(toParent: nil)
        addChild(toViewController)
        
        toViewController.view.frame = fromViewController.view.bounds
        
        animationGroup.enter()
        transition(
            from: fromViewController,
            to: toViewController,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                self.view.bringSubviewToFront(fromViewController.view)
                fromViewController.view.alpha = 0
            }, completion: { _ in
                fromViewController.removeFromParent()
                toViewController.didMove(toParent: self)
                animationGroup.leave()
            })
        
        childViewController = toViewController
        
        animationGroup.notify(queue: .main) {
            completion?()
        }
    }
}
