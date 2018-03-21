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

enum OfflineBarState {
    case minimized
    case expanded
}

class OfflineBar: UIView {

    private let offlineLabel: UILabel
    private var heightConstraint: NSLayoutConstraint?
    private var _state: OfflineBarState = .minimized

    var state: OfflineBarState {
        set {
            update(state: newValue, animated: false)
        }
        get {
            return _state
        }
    }

    func update(state: OfflineBarState, animated: Bool) {
        guard self.state != state else { return }

        _state = state

        updateViews(animated: animated)
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        offlineLabel = UILabel()

        super.init(frame: frame)
        backgroundColor = UIColor(rgb:0xFEBF02, alpha: 1)

        layer.cornerRadius = CGFloat.OfflineBar.expandedCornerRadius
        layer.masksToBounds = true

        offlineLabel.font = FontSpec(FontSize.small, .medium).font
        offlineLabel.textColor = UIColor.white
        offlineLabel.text = "system_status_bar.no_internet.title".localized.uppercased()

        addSubview(offlineLabel)

        createConstraints()
        updateViews(animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        constrain(self, offlineLabel) { containerView, offlineLabel in
            offlineLabel.center == containerView.center
            offlineLabel.left >= containerView.leftMargin
            offlineLabel.right <= containerView.rightMargin

            heightConstraint = containerView.height == 0
        }
    }

    private func updateViews(animated: Bool = true) {
        heightConstraint?.constant = state == .expanded ? CGFloat.OfflineBar.expandedHeight : 0
        offlineLabel.alpha = state == .expanded ? 1 : 0
        layer.cornerRadius = state == .expanded ? CGFloat.OfflineBar.expandedCornerRadius : CGFloat.SyncBar.cornerRadius
    }

}

enum NetworkStatusViewState {
    case online
    case onlineSynchronizing
    case offlineExpanded
}

protocol NetworkStatusViewDelegate: class {

    /// Set this var to true after viewDidAppear. This flag prevents first layout animation when the UIViewController is created but not yet appear, if didChangeHeight called with animated = true.
    var shouldAnimateNetworkStatusView: Bool { get set }

    /// bottom margin to the neighbour view
    var bottomMargin: CGFloat { get }

    /// When the networkStatusView changes its height, this delegate method is called. The delegate should refresh its layout in the method.
    ///
    /// - Parameters:
    ///   - networkStatusView: the delegate caller
    ///   - animated: networkStatusView changes height animated?
    ///   - state: the new NetworkStatusViewState of networkStatusView
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState)
}

// MARK: - default implementation of didChangeHeight, animates the layout process
extension NetworkStatusViewDelegate where Self: UIViewController {
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState) {

        guard shouldAnimateNetworkStatusView else { return }
        
        if animated {
            UIView.animate(withDuration: TimeInterval.NetworkStatusBar.resizeAnimationTime, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            self.view.layoutIfNeeded()
        }

    }
}

class NetworkStatusView: UIView {
    private let connectingView: BreathLoadingBar
    private let offlineView: OfflineBar
    private var _state: NetworkStatusViewState = .online

    private lazy var topMargin = UIScreen.hasNotch ? CGFloat(0) : CGFloat.NetworkStatusBar.topMargin

    public weak var delegate: NetworkStatusViewDelegate! {
        didSet {
            createConstraints()
        }
    }

    var offlineViewTopMargin: NSLayoutConstraint?
    var offlineViewBottomMargin: NSLayoutConstraint?
    var connectingViewHeight: NSLayoutConstraint?
    var connectingViewBottomMargin: NSLayoutConstraint?
    fileprivate var application: ApplicationProtocol = UIApplication.shared

    var state: NetworkStatusViewState {
        set {
            update(state: newValue, animated: false)
        }
        get {
            return _state
        }
    }

    func update(state: NetworkStatusViewState, animated: Bool) {
        _state = state
        // if this is called before the frame is set then the offline
        // bar zooms into view (which we don't want).
        updateViewState(animated: (frame == .zero) ? false : animated)
    }

    /// init method with a parameter for injecting mock application
    ///
    /// - Parameter application: Provide this param for testing only
    convenience init(application: ApplicationProtocol = UIApplication.shared) {
        self.init(frame: .zero)

        self.application = application
    }

    override init(frame: CGRect) {
        connectingView = BreathLoadingBar.withDefaultAnimationDuration()
        connectingView.accessibilityIdentifier = "LoadBar"
        connectingView.backgroundColor = UIColor.accent()
        offlineView = OfflineBar()

        super.init(frame: frame)

        connectingView.delegate = self

        [offlineView, connectingView].forEach(addSubview)

        state = .online
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {
        let bottomMargin = delegate.bottomMargin

        constrain(self, offlineView, connectingView) { containerView, offlineView, connectingView in
            offlineView.left == containerView.left + CGFloat.NetworkStatusBar.horizontalMargin
            offlineView.right == containerView.right - CGFloat.NetworkStatusBar.horizontalMargin
            offlineViewTopMargin = offlineView.top == containerView.top + topMargin
            offlineViewBottomMargin = offlineView.bottom == containerView.bottom - bottomMargin

            connectingView.left == offlineView.left
            connectingView.right == offlineView.right
            connectingView.top == offlineView.top
            connectingViewHeight = connectingView.height == CGFloat.SyncBar.height
            connectingViewBottomMargin = connectingView.bottom == containerView.bottom - bottomMargin
        }
    }

    private func updateViewState(animated: Bool) {
        var connectingViewHidden = state != .onlineSynchronizing
        connectingView.animating = state == .onlineSynchronizing
        let offlineViewHidden = state != .offlineExpanded

        var offlineBarState: OfflineBarState?
        switch state {
        case .offlineExpanded:
            offlineBarState = .expanded
        case .online, .onlineSynchronizing:
            offlineBarState = .minimized
        }

        // When the app is in background, hide the sync bar. It prevents the sync bar is "disappear in a blink" visual artifact.
        if application.applicationState == .background {
            connectingViewHidden = true
        }

        if let offlineBarState = offlineBarState {

            let updateUIBlock: () -> Void = {
                self.updateUI(
                    offlineBarState: offlineBarState,
                    animated: animated,
                    connectingViewHidden: connectingViewHidden,
                    offlineViewHidden: offlineViewHidden
                )
            }

            let completionBlock: () -> Void = {
                self.updateUICompletion(
                    connectingViewHidden: connectingViewHidden,
                    offlineViewHidden: offlineViewHidden
                )
            }

            if animated {
                if offlineBarState == .expanded {
                    self.offlineView.isHidden = false
                }

                UIView.animate(
                    withDuration: TimeInterval.NetworkStatusBar.resizeAnimationTime,
                    delay: 0,
                    options: [.curveEaseInOut, .beginFromCurrentState],
                    animations: updateUIBlock,
                    completion: { _ in completionBlock() }
                )
            } else {
                updateUIBlock()
                completionBlock()
            }

            delegate?.didChangeHeight(self, animated: animated, state: state)
        }
    }

    func updateUI(offlineBarState: OfflineBarState,
                  animated: Bool,
                  connectingViewHidden: Bool,
                  offlineViewHidden: Bool) {
        offlineViewBottomMargin?.constant = offlineBarState == .expanded ? -delegate.bottomMargin : 0
        offlineViewTopMargin?.constant = offlineBarState == .expanded ? topMargin : 0

        connectingViewHeight?.constant = connectingViewHidden ? 0 : CGFloat.SyncBar.height
        connectingViewBottomMargin?.constant = connectingViewHidden ? 0 : -delegate.bottomMargin

        /// offlineViewBottomMargin is active iff connectingViewHidden is visible
        if offlineViewHidden && !connectingViewHidden {
            offlineViewBottomMargin?.isActive = false
            connectingViewBottomMargin?.isActive = true
        }
        else {
            connectingViewBottomMargin?.isActive = false
            offlineViewBottomMargin?.isActive = true
        }

        self.offlineView.update(state: offlineBarState, animated: animated)

        self.layoutIfNeeded()
    }

    func updateUICompletion(connectingViewHidden: Bool, offlineViewHidden: Bool) {
        self.offlineView.isHidden = offlineViewHidden
    }

    // Detects when the view can be touchable
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return state == .offlineExpanded
    }
}

extension NetworkStatusView: BreathLoadingBarDelegate {
    func animationDidStarted() {
        delegate?.didChangeHeight(self, animated: true, state: state)
    }

    func animationDidStopped() {
        delegate?.didChangeHeight(self, animated: true, state: state)
    }
}

