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

@objc final class NetworkStatusViewController : UIViewController {
    
    fileprivate let networkStatusView = NetworkStatusView()
    fileprivate var networkStatusObserverToken : Any?
    fileprivate var pendingState : NetworkStatusViewState?
    fileprivate var offlineBarTimer : Timer?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)

        offlineBarTimer?.invalidate()
        offlineBarTimer = nil
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

    @objc public func createConstraints(bottomView: UIView, containerView: UIView, topMargin: CGFloat) {
        constrain(bottomView, containerView, self.view) { (bottomView: LayoutProxy, view: LayoutProxy, networkStatusViewControllerView: LayoutProxy) -> Void in

            networkStatusViewControllerView.top == view.top + topMargin
            networkStatusViewControllerView.left == view.left
            networkStatusViewControllerView.right == view.right

            bottomView.top == networkStatusViewControllerView.bottom
        }

    }

    public func setNetworkStatusViewDelegate(delegate: NetworkStatusViewDelegate) {
        self.networkStatusView.delegate = delegate
    }
    
    public func notifyWhenOffline() -> Bool {
        if networkStatusView.state == .offlineCollapsed {
            update(state: .offlineExpanded)
        }
        
        return networkStatusView.state == .offlineExpanded || networkStatusView.state == .offlineCollapsed
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
        offlineBarTimer = .allVersionCompatibleScheduledTimer(withTimeInterval: 2.0, repeats: false) {
            [weak self] _ in
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
    
    fileprivate func update(state : NetworkStatusViewState) {
        networkStatusView.update(state: state, animated: true)
    }

}

extension NetworkStatusViewController : ZMNetworkAvailabilityObserver {
    
    func didChangeAvailability(newState: ZMNetworkState) {
        enqueue(state: viewState(from: newState))
    }
    
}
