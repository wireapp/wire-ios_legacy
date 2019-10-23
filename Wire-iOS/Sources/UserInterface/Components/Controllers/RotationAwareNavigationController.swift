// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

final class RotationAwareNavigationController: UINavigationController, PopoverPresenter {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)///TODO: also called when dismiss child
    } ///TODO: viewDidDismiss??

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // PopoverPresenter
    weak var presentedPopover: UIPopoverPresentationController?
    weak var popoverPointToView: UIView?    
    
    override var shouldAutorotate : Bool {
        if let topController = self.viewControllers.last {
            return topController.shouldAutorotate
        }
        else {
            return super.shouldAutorotate
        }
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if let topController = self.viewControllers.last {
            return topController.supportedInterfaceOrientations
        }
        else {
            return super.supportedInterfaceOrientations
        }
    }
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        if let topController = self.viewControllers.last {
            return topController.preferredInterfaceOrientationForPresentation
        }
        else {
            return super.preferredInterfaceOrientationForPresentation
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        if let topController = self.viewControllers.last {
            return topController.prefersStatusBarHidden
        }
        else {
            return super.prefersStatusBarHidden
        }
    }
    
    public override var preferredStatusBarStyle : UIStatusBarStyle {
        if let topController = self.viewControllers.last {
            return topController.preferredStatusBarStyle
        }
        else {
            return super.preferredStatusBarStyle
        }
    }
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        viewControllers.forEach { $0.hideDefaultButtonTitle() }
        
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.hideDefaultButtonTitle()
        
        super.pushViewController(viewController, animated: animated)
    }
    
}
