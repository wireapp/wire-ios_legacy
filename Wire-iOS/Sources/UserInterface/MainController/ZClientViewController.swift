//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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


import Foundation


extension ZClientViewController {
    
    func setTopOverlay(to viewController: UIViewController?, animated: Bool = true) {
        topOverlayViewController?.willMove(toParentViewController: nil)
        
        if let previousViewController = topOverlayViewController, animated {
            if let viewController = viewController {
                addChildViewController(viewController)
                transition(from: previousViewController,
                           to: viewController,
                           duration: 0.5,
                           options: .transitionCrossDissolve,
                           animations: nil,
                           completion: { (finished) in
                            viewController.didMove(toParentViewController: self)
                            previousViewController.removeFromParentViewController()
                            self.topOverlayViewController = viewController
                            
                            UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(true)
                })
            }
            else {
                let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)

                UIView.wr_animate(easing: RBBEasingFunctionEaseInExpo, duration: 0.35, delay: 0, animations: {
                    heightConstraint.isActive = true
                    
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }, options: .beginFromCurrentState, completion: { completed in
                    heightConstraint.autoRemove()
                    
                    self.topOverlayViewController?.removeFromParentViewController()
                    previousViewController.view.removeFromSuperview()
                    self.topOverlayViewController = viewController
                })
            }
        }
        else {
            topOverlayViewController?.removeFromParentViewController()
            if let viewController = viewController {
                addChildViewController(viewController)
                viewController.view.frame = topOverlayContainer.bounds
                
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                topOverlayContainer.addSubview(viewController.view)
                NSLayoutConstraint.activate([
                    viewController.view.topAnchor.constraint(equalTo: topOverlayContainer.topAnchor),
                    viewController.view.leadingAnchor.constraint(equalTo: topOverlayContainer.leadingAnchor),
                    viewController.view.bottomAnchor.constraint(equalTo: topOverlayContainer.bottomAnchor),
                    viewController.view.trailingAnchor.constraint(equalTo: topOverlayContainer.trailingAnchor),
                    ])
                
                topOverlayContainer.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
                
                if animated {
                    let heightConstraint = viewController.view.heightAnchor.constraint(equalToConstant: 0)
                    heightConstraint.isActive = true
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                    
                    UIView.wr_animate(easing: RBBEasingFunctionEaseOutExpo, duration: 0.35, delay: 0.5, animations: {
                        heightConstraint.autoRemove()
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    }, options: .beginFromCurrentState, completion: { _ in })
                }
                
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
            }
            topOverlayViewController = viewController
        }
    }
    
    func createTopViewConstraints() {
        topOverlayContainer = UIView()
        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        contentTopRegularConstraint = splitViewController.view.topAnchor.constraint(equalTo: safeTopAnchor)
        contentTopCompactConstraint = splitViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
            topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor),
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topOverlayContainer.bottomAnchor.constraint(equalTo: splitViewController.view.topAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriorityDefaultLow
        heightConstraint.isActive = true
    }

    @objc(refreshSplitViewPositionForRegularContainer:)
    func refreshSplitViewPosition(isRegularContainer: Bool) {
        contentTopRegularConstraint.isActive = isRegularContainer
        contentTopCompactConstraint.isActive = !isRegularContainer
    }

}
