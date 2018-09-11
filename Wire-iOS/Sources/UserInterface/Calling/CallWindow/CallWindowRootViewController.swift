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


final class CallWindowRootViewController: UIViewController {
    
    private var callController: CallController?
    
    @objc func minimizeOverlay(completion: @escaping () -> Void) {
        guard let callController = callController else { return completion() }
        
        callController.minimizeCall(completion: completion)
    }
    
    @objc var isDisplayingCallOverlay: Bool {
        return callController?.activeCallViewController != nil
    }
    
    override var prefersStatusBarHidden: Bool {
        return callController?.activeCallViewController?.prefersStatusBarHidden ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return callController?.activeCallViewController?.preferredStatusBarStyle ?? .default
    }
    
    override var shouldAutorotate: Bool {
        return topmostViewController()?.shouldAutorotate ?? true
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
        guard let topmost = UIApplication.shared.wr_topmostViewController() else { return nil }
        guard topmost != self, !topmost.isKind(of: CallWindowRootViewController.self) else { return nil }
        return topmost
    }
    
}
