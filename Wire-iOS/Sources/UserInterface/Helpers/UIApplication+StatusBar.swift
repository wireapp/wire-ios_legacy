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

extension UIApplication {
    
    static let wr_statusBarStyleChangeNotification: Notification.Name = Notification.Name("wr_statusBarStyleChangeNotification")

    /// return the visible window on the top most which fulfills these conditions:
    /// 1. the windows has rootViewController
    /// 2. the window's rootViewController is RootViewController
    var topMostVisibleWindow: UIWindow? {
        let orderedWindows = windows.sorted { win1, win2 in
            win1.windowLevel < win2.windowLevel
        }

        let visibleWindow = orderedWindows.filter {
            guard let controller = $0.rootViewController else {
                return false
            }

            if controller is RootViewController  {
                return true
            }
            
            return false
        }

        return visibleWindow.last
    }


    /// Get the top most view controller
    ///
    /// - Parameter onlyFullScreen: if false, also search for all kinds of presented view controller
    /// - Returns: the top most view controller 
    func topmostViewController(onlyFullScreen: Bool = true) -> UIViewController? {

        guard let window = topMostVisibleWindow,
            var topController = window.rootViewController else {
                return .none
        }
        
        while let presentedController = topController.presentedViewController,
            (!onlyFullScreen || presentedController.modalPresentationStyle == .fullScreen) {
            topController = presentedController
        }
        
        return topController
    }
    
    @available(iOS 12.0, *)
    static var userInterfaceStyle: UIUserInterfaceStyle? {
            UIApplication.shared.keyWindow?.rootViewController?.traitCollection.userInterfaceStyle
    }
}

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
    override open var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
}
