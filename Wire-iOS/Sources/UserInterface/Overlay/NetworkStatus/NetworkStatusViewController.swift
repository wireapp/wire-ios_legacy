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

@objc final class NetworkStatusViewController: UIViewController {
    
    public weak var delegate: NetworkStatusBarDelegate? {
        didSet {
            networkStatusView.delegate = delegate
        }
    }
    
    static private var selfInstances: [NetworkStatusViewController] = []
    static private var shared: NetworkStatusViewController? {
        get {
            for networkStatusViewController in selfInstances {
                if networkStatusViewController.shouldShowOnIPad(for: networkStatusViewController.uIIdiomSizeClassOrientationProtocol.current().orientation) {
                    return networkStatusViewController
                }
                
            }
            return nil
        }
    }
    
    fileprivate let networkStatusView = NetworkStatusView()
    fileprivate var networkStatusObserverToken: Any?
    fileprivate var pendingState: NetworkStatusViewState?
    fileprivate var state: NetworkStatusViewState?
    fileprivate var finishedViewWillAppear: Bool = false
    fileprivate let uIIdiomSizeClassOrientationProtocol: UIIdiomSizeClassOrientationProtocol.Type
    
    init(_ uIIdiomSizeClassOrientationProtocol: UIIdiomSizeClassOrientationProtocol.Type = UIIdiomSizeClassOrientation.self) {
        self.uIIdiomSizeClassOrientationProtocol = uIIdiomSizeClassOrientationProtocol
        super.init(nibName: nil, bundle: nil)
        NetworkStatusViewController.selfInstances.append(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)
        
        if let index = NetworkStatusViewController.selfInstances.index(of: self) {
            NetworkStatusViewController.selfInstances.remove(at: index)
        }
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
    
    @objc public func createConstraints(bottomView: UIView, containerView: UIView, topMargin: CGFloat) {
        constrain(bottomView, containerView, self.view) { (bottomView: LayoutProxy, view: LayoutProxy, networkStatusViewControllerView: LayoutProxy) -> Void in
            
            networkStatusViewControllerView.top == view.top + topMargin
            networkStatusViewControllerView.left == view.left
            networkStatusViewControllerView.right == view.right
            
            bottomView.top == networkStatusViewControllerView.bottom
        }
        
    }
    
    static public func notifyWhenOffline() -> Bool {
        guard let shared = NetworkStatusViewController.shared else { return true }
        let networkStatusView = shared.networkStatusView
        
        if networkStatusView.state == .offlineCollapsed {
            shared.update(state: .offlineExpanded)
        }
        
        return networkStatusView.state == .offlineExpanded || networkStatusView.state == .offlineCollapsed
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
    
    fileprivate func update(state: NetworkStatusViewState) {
        self.state = state
        guard shouldShowOnIPad(for: UIIdiomSizeClassOrientation.current().orientation) else { return }
        
        networkStatusView.update(state: state, animated: true)
    }
    
    func shouldShowOnIPad(for newOrientation: Orientation?) -> Bool {
        
        guard let delegate = self.delegate, let newOrientation = newOrientation else { return true }
        
        switch newOrientation
        {
        case .landscape:
            return delegate.shouldShowNetworkStatusUIInIPadRegularLandscape
        case .portrait:
            return delegate.shouldShowNetworkStatusUIInIPadRegularPortrait
        case .unknown:
            return true
        }
    }
    
}

extension NetworkStatusViewController: ZMNetworkAvailabilityObserver {
    
    func didChangeAvailability(newState: ZMNetworkState) {
        enqueue(state: viewState(from: newState))
    }
    
}

// MARK: - iPad size class and orientation switching

extension NetworkStatusViewController {
    func updateStateForIPad(for newOrientation: Orientation?) {
        if shouldShowOnIPad(for: newOrientation) {
            if let state = state {
                networkStatusView.update(state: state, animated: false)
            }
        } else {
            /// when size class changes and delegate view controller disabled to show networkStatusView, hide the networkStatusView
            networkStatusView.update(state: .online, animated: false)
            //self.delegate?.didChangeHeight(networkStatusView, animated: false, state: .online)
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        updateStateForIPad(for: uIIdiomSizeClassOrientationProtocol.current().orientation)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        var newOrientation = Orientation.unknown
        if size.width > 0 {
            if size.width > size.height {
            newOrientation =  .landscape
            }
            else if size.width < size.height {
                newOrientation =  .portrait
            }
        }
        
        updateStateForIPad(for: newOrientation)
    }
    
}

