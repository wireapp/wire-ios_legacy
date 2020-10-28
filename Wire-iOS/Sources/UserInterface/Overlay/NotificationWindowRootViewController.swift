//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import Cartography
import UIKit
import WireCommonComponents

final class NotificationWindowRootViewController: UIViewController {
    
    private(set) var dimmedViewController: DimmedViewController = DimmedViewController()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if dimmedViewController.parent == self {
            dimmedViewController.wr_removeFromParentViewController()
        }
    }
    
    override func loadView() {
        view = PassthroughTouchesView()
    }
    
    private func setupConstraints() {
        dimmedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        dimmedViewController.view.fitInSuperview()
    }
    
    @objc func applicationWillResignActive() {
        if nil != dimmedViewController.parent {
            dimmedViewController.wr_removeFromParentViewController()
        }
        
        add(dimmedViewController, to: view)
        
        setupConstraints()
        AppDelegate.shared.notificationsWindow?.isHidden = !AppLock.isActive
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        AppDelegate.shared.notificationsWindow?.isHidden = true
    }

    // MARK: - Rotation handling (should match up with root)

    private var topmostViewController: UIViewController? {
        guard let topmostViewController = UIApplication.shared.topmostViewController() else { return nil}

        if topmostViewController != self && !(topmostViewController is NotificationWindowRootViewController) {
            return topmostViewController
        }
        
        return nil
    }

    override var shouldAutorotate: Bool {
        return topmostViewController?.shouldAutorotate ?? true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topmostViewController?.supportedInterfaceOrientations ?? wr_supportedInterfaceOrientations
    }
    
    // MARK: - status bar
    
    override var childForStatusBarStyle: UIViewController? {
        return dimmedViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return dimmedViewController
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

// MARK : - Child
fileprivate extension UIViewController {
    func wr_removeFromParentViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

}

final class DimmedViewController: UIViewController {
    let blurView: UIVisualEffectView = UIVisualEffectView.blurView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(blurView)
        constrain(self.view, self.blurView) { view, blurView in
            blurView.edges == view.edges
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
