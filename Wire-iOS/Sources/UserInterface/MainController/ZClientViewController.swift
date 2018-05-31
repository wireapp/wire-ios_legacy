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
                            self.updateSplitViewTopConstraint()
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
                    self.topOverlayViewController = nil
                    self.updateSplitViewTopConstraint()
                })
            }
        }
        else if let viewController = viewController {
            addChildViewController(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            topOverlayContainer.addSubview(viewController.view)
            viewController.view.fitInSuperview()
            
            viewController.didMove(toParentViewController: self)
            
            let isRegularContainer = traitCollection.horizontalSizeClass == .regular
            
            if animated && !isRegularContainer {
                let heightConstraint = viewController.view.heightAnchor.constraint(equalToConstant: 0)
                heightConstraint.isActive = true
                
                self.topOverlayViewController = viewController
                self.updateSplitViewTopConstraint()
                
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                UIView.wr_animate(easing: RBBEasingFunctionEaseOutExpo, duration: 0.35, delay: 0.5, animations: {
                    heightConstraint.autoRemove()
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }, options: .beginFromCurrentState, completion: { _ in
                    UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
                })
            }
            else {
                UIApplication.shared.wr_updateStatusBarForCurrentControllerAnimated(animated)
                topOverlayViewController = viewController
                updateSplitViewTopConstraint()
            }
        }
    }
    
    func createTopViewConstraints() {
        topOverlayContainer = UIView()
        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        contentTopRegularConstraint = topOverlayContainer.topAnchor.constraint(equalTo: safeTopAnchor)
        contentTopCompactConstraint = topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor)
        
        NSLayoutConstraint.activate([
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

    func updateSplitViewTopConstraint() {

        let isRegularContainer = traitCollection.horizontalSizeClass == .regular
        
        if isRegularContainer && nil == topOverlayViewController {
            contentTopCompactConstraint.isActive = false
            contentTopRegularConstraint.isActive = true
        } else {
            contentTopRegularConstraint.isActive = false
            contentTopCompactConstraint.isActive = true
        }

    }

    func openClientListScreen(for user: ZMUser) {
        if user.isSelfUser {
            let clientListViewController = ClientListViewController(clientsList: Array(user.clients), credentials: nil, detailedView: true, showTemporary: true)
            //        clientListViewController.view.backgroundColor = [UIColor blackColor];
            clientListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissClientListController(_:)))
            //        UINavigationController *navWrapperController = [[SettingsStyleNavigationController alloc] initWithRootViewController:clientListViewController];
            let navWrapperController: UINavigationController? = clientListViewController.wrapInNavigationController()
            navWrapperController?.modalPresentationStyle = .formSheet
            if let aController = navWrapperController {
                present(aController, animated: true)
            }
        } else {
            let profileViewController = ProfileViewController(user: user, context: .deviceList)

            if let conversationViewController = (conversationRootViewController as? ConversationRootViewController)?.conversationViewController {
                profileViewController.delegate = conversationViewController as? ProfileViewControllerDelegate

                profileViewController.viewControllerDismisser = conversationViewController as? ViewControllerDismisser
            }
            let navWrapperController: UINavigationController? = profileViewController.wrapInNavigationController()
            navWrapperController?.modalPresentationStyle = .formSheet
            if let aController = navWrapperController {
                present(aController, animated: true)
            }
        }
    }
}
