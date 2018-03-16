//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import Cartography

typealias NetworkStatusBarDelegate = NetworkStatusViewControllerDelegate & NetworkStatusViewDelegate

protocol NetworkStatusViewControllerDelegate: class {
    /// if return false, NetworkStatusViewController will not disapper in iPad regular mode landscape orientation.
    var showInIPadLandscapeMode: Bool {get}

    /// if return false, NetworkStatusViewController will not disapper in iPad regular mode portrait orientation.
    var showInIPadPortraitMode: Bool {get}
}

extension Notification.Name {
    static let ShowNetworkStatusBar = Notification.Name("ShowNetworkStatusBar")
}

@objc
class NetworkStatusViewController : UIViewController {

    public weak var delegate: NetworkStatusBarDelegate? {
        didSet {
            networkStatusView.delegate = delegate
        }
    }

    let networkStatusView = NetworkStatusView()
    fileprivate var networkStatusObserverToken: Any?
    fileprivate var pendingState: NetworkStatusViewState?
    var state: NetworkStatusViewState?
    fileprivate var finishedViewWillAppear: Bool = false

    fileprivate var device: DeviceProtocol = UIDevice.current
    fileprivate var application: ApplicationProtocol = UIApplication.shared

    /// default init method with a parameter for injecting mock device
    ///
    /// - Parameter device: Provide this param for testing only
    /// - Parameter application: Provide this param for testing only
    convenience init(device: DeviceProtocol = UIDevice.current, application: ApplicationProtocol = UIApplication.shared) {
        self.init(nibName: nil, bundle: nil)

        self.device = device
        self.application = application
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        NotificationCenter.default.addObserver(self, selector: #selector(changeStateFormOfflineCollapsedToOfflineExpanded), name: Notification.Name.ShowNetworkStatusBar, object: .none)

        NotificationCenter.default.addObserver(self, selector: #selector(updateStateForIPad), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: .none)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        let passthroughTouchesView = PassthroughTouchesView()
        passthroughTouchesView.clipsToBounds = true
        self.view = passthroughTouchesView
    }

    override func viewDidLoad() {
        view.addSubview(networkStatusView)

        constrain(self.view, networkStatusView) { containerView, networkStatusView in
            networkStatusView.left == containerView.left
            networkStatusView.right == containerView.right
            networkStatusView.top == containerView.top
            networkStatusView.height == containerView.height
        }

        if let userSession = ZMUserSession.shared() {
            update(state: viewState(from: userSession.networkState))
            networkStatusObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(self, userSession: userSession)
        }

        networkStatusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnNetworkStatusBar)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard !finishedViewWillAppear else { return }

        finishedViewWillAppear = true
        if let userSession = ZMUserSession.shared() {
            update(state: viewState(from: userSession.networkState))
        }
    }

    @objc public func createConstraintsInContainer(bottomView: UIView, containerView: UIView, topMargin: CGFloat) {
        constrain(bottomView, containerView, view) { bottomView, containerView, networkStatusViewControllerView in

            networkStatusViewControllerView.top == containerView.top + topMargin
            networkStatusViewControllerView.left == containerView.left
            networkStatusViewControllerView.right == containerView.right
            bottomView.top == networkStatusViewControllerView.bottom
        }
    }

    func changeStateFormOfflineCollapsedToOfflineExpanded() {
        let networkStatusView = self.networkStatusView

        if networkStatusView.state == .offlineCollapsed {
            self.update(state: .offlineExpanded)
        }
    }


    /// show NetworkStatusViewController instance(s) if its state is .offlineCollapsed
    static public func notifyWhenOffline() {
        NotificationCenter.default.post(name: .ShowNetworkStatusBar, object: self)
    }

    func showOfflineAlert() {
        let offlineAlert = UIAlertController.init(title: "system_status_bar.no_internet.title".localized,
                                                  message: "system_status_bar.no_internet.explanation".localized,
                                                  cancelButtonTitle: "general.confirm".localized)
        offlineAlert.presentTopmost()
    }

    fileprivate func viewState(from networkState: ZMNetworkState) -> NetworkStatusViewState {
        switch networkState {
        case .offline:
            return .offlineExpanded
        case .online:
            return .online
        case .onlineSynchronizing:
            return .onlineSynchronizing
        }
    }

    internal func tappedOnNetworkStatusBar() {
        switch networkStatusView.state {
        case .offlineCollapsed:
            update(state: .offlineExpanded)
        case .offlineExpanded:
            showOfflineAlert()
        default:
            break
        }
    }

    internal func collapseOfflineBar() {
        if networkStatusView.state == .offlineExpanded {
            update(state: .offlineCollapsed)
        }
    }

    fileprivate func enqueue(state: NetworkStatusViewState) {
        pendingState = state
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)
        perform(#selector(applyPendingState), with: nil, afterDelay: 1)
    }

    internal func applyPendingState() {
        guard let state = pendingState else { return }
        update(state: state)
        pendingState = nil
    }

    func update(state: NetworkStatusViewState) {
        self.state = state
        guard shouldShowOnIPad() else { return }

        networkStatusView.update(state: state, animated: true)
    }
}

extension NetworkStatusViewController: ZMNetworkAvailabilityObserver {

    func didChangeAvailability(newState: ZMNetworkState) {
        enqueue(state: viewState(from: newState))
    }

}

// MARK: - iPad size class and orientation switching

extension NetworkStatusViewController {
    func shouldShowOnIPad() -> Bool {
        guard isIPadRegular(device: device) else { return true }
        guard let delegate = self.delegate else { return true }

        let newOrientation = application.statusBarOrientation

        if newOrientation.isPortrait {
            return delegate.showInIPadPortraitMode
        } else if newOrientation.isLandscape {
            return delegate.showInIPadLandscapeMode
        } else {
            return true
        }
    }

    func updateStateForIPad() {
        guard device.userInterfaceIdiom == .pad else { return }
        guard let state = self.state else { return }

        switch self.traitCollection.horizontalSizeClass {
        case .regular:
            if shouldShowOnIPad() {
                networkStatusView.update(state: state, animated: false)
            } else {
                /// when size class changes and delegate view controller disabled to show networkStatusView, hide the networkStatusView
                networkStatusView.update(state: .online, animated: false)
            }
        case .compact, .unspecified:
            networkStatusView.update(state: state, animated: false)
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateStateForIPad()
    }
}
