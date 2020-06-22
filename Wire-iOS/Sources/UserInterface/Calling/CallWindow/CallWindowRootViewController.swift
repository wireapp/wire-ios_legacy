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
import UIKit

final class CallWindowRootViewController: UIViewController {
    
    private var callController: CallController?
    
    func minimizeOverlay(animated: Bool, completion: Completion?) {
        guard let callController = callController else {
            completion?()
            return            
        }
        
        callController.minimizeCall(animated: animated, completion: completion)
    }
    
    var isDisplayingCallOverlay: Bool {
        return callController?.activeCallViewController != nil
    }
    
    private var child: UIViewController? {
        return callController?.activeCallViewController ?? topmostViewController()
    }

    override var childForStatusBarStyle: UIViewController? {
        return child
    }

    override var childForStatusBarHidden: UIViewController? {
        return child
    }

    override var shouldAutorotate: Bool {
        if isHorizontalSizeClassRegular {
            return topmostViewController()?.shouldAutorotate ?? true
        }
        
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topmostViewController()?.supportedInterfaceOrientations ?? wr_supportedInterfaceOrientations
    }
    
    override func loadView() {
        view = PassthroughTouchesView()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func transitionToLoggedInSession() {
        callController = CallController()
        callController?.targetViewController = self
    }
    
    func presentCallCurrentlyInProgress() {
        callController?.updateState()
    }
    
    private func topmostViewController() -> UIViewController? {
        guard let topmost = UIApplication.shared.topmostViewController() else { return nil }
        guard topmost != self, !topmost.isKind(of: CallWindowRootViewController.self) else { return nil }
        return topmost
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        view.window?.isHidden = false
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            self.view.window?.isHidden = true
        }
    }

}
