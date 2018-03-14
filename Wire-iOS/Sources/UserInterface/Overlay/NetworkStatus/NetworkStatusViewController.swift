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
    var shouldShowNetworkStatusUIInIPadRegularLandscape: Bool {get}

    /// if return false, NetworkStatusViewController will not disapper in iPad regular mode portrait orientation.
    var shouldShowNetworkStatusUIInIPadRegularPortrait: Bool {get}
}

extension NetworkStatusViewController {
    // static pointer for global access
    static weak var selfInConversationRootView: NetworkStatusViewController?
    static weak var selfInConversationListView: NetworkStatusViewController?
}

@objc
class NetworkStatusViewController : UIViewController {

    public weak var delegate: NetworkStatusBarDelegate? {
        didSet {
            networkStatusView.delegate = delegate
        }
    }

    let networkStatusView = NetworkStatusView()
    fileprivate var networkStatusObserverToken : Any?
    fileprivate var pendingState : NetworkStatusViewState?
    var state: NetworkStatusViewState?
    fileprivate var offlineBarTimer : Timer?
    fileprivate var device: DeviceProtocol = UIDevice.current
    fileprivate var container: ContainerType

    override func loadView() {
        let passthroughTouchesView = PassthroughTouchesView()
        passthroughTouchesView.clipsToBounds = true
        self.view = passthroughTouchesView
    }

    enum ContainerType {
        case conversationList
        case conversationRoot
    }

    /// default init method with a parameter for injecting mock device
    ///
    /// - Parameter device: Provide this param for testing only
    init(container: ContainerType, device: DeviceProtocol = UIDevice.current) {
        self.container = container

        super.init(nibName: nil, bundle: nil)

        switch container {
        case .conversationList:
            NetworkStatusViewController.selfInConversationListView = self

        case .conversationRoot:
            NetworkStatusViewController.selfInConversationRootView = self
        }

        self.device = device
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)

        offlineBarTimer?.invalidate()
        offlineBarTimer = nil

        switch self.container {
        case .conversationList:
            NetworkStatusViewController.selfInConversationListView = nil

        case .conversationRoot:
            NetworkStatusViewController.selfInConversationRootView = nil
        }
    }
    
    override func viewDidLoad() {
        view.addSubview(networkStatusView)
        
        constrain(self.view, networkStatusView) { containerView, networkStatusView in
            networkStatusView.left == containerView.left
            networkStatusView.right == containerView.right
            networkStatusView.top == containerView.top
        }

        if let userSession = ZMUserSession.shared() {
            update(state: viewState(from: userSession.networkState))
            networkStatusObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(self, userSession: userSession)
        }
        
        networkStatusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnNetworkStatusBar)))
    }

    func chnageStateFormOfflineCollapsedToOfflineExpanded() {
        let networkStatusView = self.networkStatusView

        if networkStatusView.state == .offlineCollapsed {
            self.update(state: .offlineExpanded)
        }
    }


    /// show NetworkStatusViewController instance(s) if its state is .offlineCollapsed
    static public func notifyWhenOffline() {
        guard let selfInList = NetworkStatusViewController.selfInConversationListView,
              let selfInRoot = NetworkStatusViewController.selfInConversationRootView
            else { return }

        // for compact mode all networkStatusViewController are notified, for regular mode returns the only enabled networkStatusViewController

        if selfInList.isIPadRegular(device: selfInList.device) {
            if selfInList.shouldShowOnIPad(for: selfInList.device.orientation) {
                selfInList.chnageStateFormOfflineCollapsedToOfflineExpanded()
            } else {
                selfInRoot.chnageStateFormOfflineCollapsedToOfflineExpanded()
            }
        }
        else {
            selfInList.chnageStateFormOfflineCollapsedToOfflineExpanded()
            selfInRoot.chnageStateFormOfflineCollapsedToOfflineExpanded()
        }
    }

    func showOfflineAlert() {
        let offlineAlert = UIAlertController.init(title: "system_status_bar.no_internet.title".localized,
                                                  message: "system_status_bar.no_internet.explanation".localized,
                                                  cancelButtonTitle: "general.confirm".localized)
        
        offlineAlert.presentTopmost()
    }
    
    fileprivate func viewState(from networkState : ZMNetworkState) -> NetworkStatusViewState {
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
    
    fileprivate func startOfflineBarTimer() {
        offlineBarTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.collapseOfflineBar()
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
    
    func update(state : NetworkStatusViewState) {
        self.state = state

        networkStatusView.update(state: state, animated: true)
        
        if state == .offlineExpanded {
            startOfflineBarTimer()
        }
    }

}

extension NetworkStatusViewController : ZMNetworkAvailabilityObserver {
    
    func didChangeAvailability(newState: ZMNetworkState) {
        enqueue(state: viewState(from: newState))
    }
    
}

// MARK: - iPad size class and orientation switching

extension NetworkStatusViewController {
    
    func shouldShowOnIPad(for newOrientation: UIDeviceOrientation?) -> Bool {
        guard isIPadRegular(device: device) else { return true }

        guard let delegate = self.delegate, let newOrientation = newOrientation else { return true }

        if newOrientation.isPortrait {
            return delegate.shouldShowNetworkStatusUIInIPadRegularPortrait
        } else if newOrientation.isLandscape {
            return delegate.shouldShowNetworkStatusUIInIPadRegularLandscape
        } else {
            return true
        }
    }

    func updateStateForIPad(for newOrientation: UIDeviceOrientation?) {
        if shouldShowOnIPad(for: newOrientation) {
            if let state = state {
                networkStatusView.update(state: state, animated: false)
            }
        } else {
            /// when size class changes and delegate view controller disabled to show networkStatusView, hide the networkStatusView
            networkStatusView.update(state: .online, animated: false)
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard device.userInterfaceIdiom == .pad else { return }

        updateStateForIPad(for: device.orientation)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator?) {
        if let coordinator = coordinator {
            super.viewWillTransition(to: size, with: coordinator)
        }

        guard isIPadRegular(device: device) else { return }

        // find out the new orientation with the new size
        var newOrientation: UIDeviceOrientation = .unknown
        if size.width > 0 {
            if size.width > size.height {
                newOrientation =  .landscapeLeft
            } else if size.width < size.height {
                newOrientation =  .portrait
            }
        }

        updateStateForIPad(for: newOrientation)
    }

}

