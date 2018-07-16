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
    
    private(set) var voiceChannelController: ActiveVoiceChannelViewController?
    
    @objc func minimizeOverlay(completion: @escaping () -> Void) {
        guard let controller = voiceChannelController else { return completion() }
        (controller as ViewControllerDismisser).dismiss(viewController: controller, completion: completion)
    }
    
    override var prefersStatusBarHidden: Bool {
        return voiceChannelController?.prefersStatusBarHidden ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return voiceChannelController?.preferredStatusBarStyle ?? .default
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
    
    func transitionToLoggedInSession() {
        let controller = ActiveVoiceChannelViewController()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addToSelf(controller)
        controller.view.fitInSuperview()
        voiceChannelController = controller
    }
    
    private func topmostViewController() -> UIViewController? {
        guard let topmost = UIApplication.shared.wr_topmostViewController() else { return nil }
        guard topmost != self, !topmost.isKind(of: CallWindowRootViewController.self) else { return nil }
        return topmost
    }
    
}

