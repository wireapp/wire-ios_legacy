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

    static public let collapsedHeight: CGFloat = 2
    static public let expandedHeight: CGFloat = 20
    static public let collapsedCornerRadius: CGFloat = 1
    static public let expandedCornerRadius: CGFloat = 6

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
        ///TODO:, margins left/right: 16pt. margin to top of screen: 28pt (iPhone 8 and older), 44pt (iPhone X), margin to navigation bar: 10pt, height: 24pt
        backgroundColor = UIColor(rgb:0xFEBF02, alpha: 1)///TODO share with Syncing bar

        layer.cornerRadius = OfflineBar.expandedCornerRadius
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

            heightConstraint = containerView.height == OfflineBar.collapsedHeight
        }
    }

    private func updateViews(animated: Bool = true) {
        heightConstraint?.constant = state == .expanded ? OfflineBar.expandedHeight : OfflineBar.collapsedHeight
        offlineLabel.alpha = state == .expanded ? 1 : 0
        layer.cornerRadius = state == .expanded ? OfflineBar.expandedCornerRadius : OfflineBar.collapsedHeight
    }

}

enum NetworkStatusViewState {
    case online
    case onlineSynchronizing
    case offlineExpanded
    case offlineCollapsed
}

protocol NetworkStatusViewDelegate: class {
    var isViewDidAppear: Bool {get set}
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState)
}

// MARK: - default implementation of didChangeHeight, animates the layout process
extension NetworkStatusViewDelegate where Self: UIViewController {
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState) {

        guard isViewDidAppear else { return }

        if animated {
            UIView.animate(withDuration: NetworkStatusView.resizeAnimationTime, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            self.view.layoutIfNeeded()
        }

    }
}

class NetworkStatusView: UIView {

    static public let resizeAnimationTime: TimeInterval = 0.5
    static public let horizontal: CGFloat = 16
    static public let verticalMargin: CGFloat = 8

    private let connectingView: BreathLoadingBar
    private let offlineView: OfflineBar
    private var _state: NetworkStatusViewState = .online
    public weak var delegate: NetworkStatusViewDelegate?

    var offlineViewTopMargin: NSLayoutConstraint?
    var offlineViewBottomMargin: NSLayoutConstraint?
    var connectingViewHeight: NSLayoutConstraint?
    var connectingViewBottomMargin: NSLayoutConstraint?

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
        updateViewState(animated: animated)
    }

    override init(frame: CGRect) {
        connectingView = BreathLoadingBar.withDefaultAnimationDuration()
        connectingView.accessibilityIdentifier = "LoadBar"
        connectingView.backgroundColor = UIColor.accent()
        offlineView = OfflineBar()

        super.init(frame: frame)

        connectingView.delegate = self

        [offlineView, connectingView].forEach(addSubview)

        createConstraints()
        state = .online
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {
        constrain(self, offlineView, connectingView) { containerView, offlineView, connectingView in
            offlineView.left == containerView.left + NetworkStatusView.horizontal
            offlineView.right == containerView.right - NetworkStatusView.horizontal
            offlineViewTopMargin = offlineView.top == containerView.top + NetworkStatusView.verticalMargin
            offlineViewBottomMargin = offlineView.bottom == containerView.bottom - NetworkStatusView.verticalMargin

            connectingView.left == offlineView.left
            connectingView.right == offlineView.right
            connectingView.top == offlineView.top
            connectingViewHeight = connectingView.height == OfflineBar.collapsedHeight
            connectingViewBottomMargin = connectingView.bottom == containerView.bottom - NetworkStatusView.verticalMargin
        }
    }

    func updateViewState(animated: Bool) {
        let connectingViewHidden = state != .onlineSynchronizing
        connectingView.animating = state == .onlineSynchronizing ///TODO: pass animated param, rename animating to spinning
        let offlineViewHidden = state != .offlineExpanded && state != .offlineCollapsed

        var offlineBarState: OfflineBarState?
        switch state {
        case .offlineExpanded:
            offlineBarState = .expanded
        case .offlineCollapsed:
            offlineBarState = .minimized
        case .online, .onlineSynchronizing:
            offlineBarState = .minimized
        }

        if let offlineBarState = offlineBarState {
            if animated {
                if offlineBarState == .expanded {
                    self.offlineView.isHidden = false
                }

                UIView.animate(withDuration: NetworkStatusView.resizeAnimationTime, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                    self.updateUI(offlineBarState: offlineBarState, animated: animated, connectingViewHidden: connectingViewHidden, offlineViewHidden: offlineViewHidden)
                }) { _ in
                    self.updateUICompletion(connectingViewHidden: connectingViewHidden, offlineViewHidden: offlineViewHidden)
                }
            } else {
                updateUI(offlineBarState: offlineBarState, animated: animated, connectingViewHidden: connectingViewHidden, offlineViewHidden: offlineViewHidden)

                updateUICompletion(connectingViewHidden: connectingViewHidden, offlineViewHidden: offlineViewHidden)
            }

            delegate?.didChangeHeight(self, animated: animated, state: state)
        }
    }

    func updateUI(offlineBarState: OfflineBarState, animated: Bool, connectingViewHidden: Bool, offlineViewHidden: Bool) {
        offlineViewTopMargin?.constant = offlineBarState == .expanded ? NetworkStatusView.verticalMargin : 0
        offlineViewBottomMargin?.constant = offlineBarState == .expanded ? -NetworkStatusView.verticalMargin : 0

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
        self.connectingView.isHidden = connectingViewHidden
        self.offlineView.isHidden = offlineViewHidden
    }

    // Detects when the view can be touchable
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return state == .offlineExpanded
    }
}

extension NetworkStatusView: BreathLoadingBarDelegate {
    func animationDidStarted() { ///TODO: animated param
        delegate?.didChangeHeight(self, animated: true, state: state)
    }

    func animationDidStopped() {
        delegate?.didChangeHeight(self, animated: true, state: state)
    }
}
