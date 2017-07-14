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


import UIKit

public extension UIApplication {
    
    public static let wr_statusBarStyleChangeNotification: Notification.Name = Notification.Name("wr_statusBarStyleChangeNotification")

    @objc public func wr_updateStatusBarForCurrentControllerAnimated(_ animated: Bool) {
        wr_updateStatusBarForCurrentControllerAnimated(animated, onlyFullScreen: true)
    }

    @objc public func wr_updateStatusBarForCurrentControllerAnimated(_ animated: Bool, onlyFullScreen: Bool) {
        let statusBarHidden: Bool
        let statusBarStyle: UIStatusBarStyle
        
        if let topContoller = self.wr_topmostController(onlyFullScreen: onlyFullScreen) {
            statusBarHidden = topContoller.prefersStatusBarHidden
            statusBarStyle = topContoller.preferredStatusBarStyle
        }
        else {
            statusBarHidden = true
            statusBarStyle = .lightContent
        }
        
        var changed = false
        
        if (self.isStatusBarHidden != statusBarHidden) {
            self.wr_setStatusBarHidden(statusBarHidden, with: animated ? .fade : .none)
            changed = true
        }
        
        if self.statusBarStyle != statusBarStyle {
            self.wr_setStatusBarStyle(statusBarStyle, animated: animated)
            changed = true
        }
        
        if changed {
            NotificationCenter.default.post(name: type(of: self).wr_statusBarStyleChangeNotification, object: self)
        }
    }

    @objc func wr_topmostViewController() -> UIViewController? {
        return wr_topmostController()
    }
    
    public func wr_topmostController(onlyFullScreen: Bool = true) -> UIViewController? {
        let orderedWindows = self.windows.sorted { win1, win2 in
            win1.windowLevel > win2.windowLevel
        }
        
        let visibleWindow = orderedWindows.filter {
            guard var controller = $0.rootViewController else {
                return false
            }
            
            if let notificationWindowRootController = controller as? NotificationWindowRootViewController,
                let voiceChannelController = notificationWindowRootController.voiceChannelController {
                controller = voiceChannelController
            }
            
            return controller.view.isHidden == false && controller.view.alpha != 0
        }
        
        guard let window = visibleWindow.last,
            var topController = window.rootViewController else {
                return .none
        }
        
        while let presentedController = topController.presentedViewController, (!onlyFullScreen || presentedController.modalPresentationStyle == .fullScreen) {
            topController = presentedController
        }
        
        return topController
    }
}

