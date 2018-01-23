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

        layer.cornerRadius = 6
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
    }

}

enum NetworkStatusViewState {
    case online
    case onlineSynchronizing
    case offlineExpanded
    case offlineCollapsed
}


protocol NetworkStatusViewDelegate: class {
    func didChangeHeight(_ networkStatusView : NetworkStatusView, animated: Bool, offlineBarState: OfflineBarState)
}

class NetworkStatusView: UIView {

    static public let resizeAnimationTime: TimeInterval = 0.35

    private let connectingView: BreathLoadingBar
    private let offlineView: OfflineBar
    private var _state: NetworkStatusViewState = .online
    public weak var delegate: NetworkStatusViewDelegate?

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

        [offlineView, connectingView].forEach(addSubview)

        createConstraints()
        state = .online
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createConstraints() {
        constrain(self, offlineView, connectingView) { containerView, offlineView, connectingView in
            containerView.height == OfflineBar.expandedHeight

            offlineView.left == containerView.left
            offlineView.right == containerView.right
            offlineView.top == containerView.top
            offlineView.bottom <= containerView.bottom

            connectingView.left == containerView.left
            connectingView.right == containerView.right
            connectingView.top == containerView.top
            connectingView.bottom <= containerView.bottom
            connectingView.height == OfflineBar.collapsedHeight
        }
    }

    func updateViewState(animated: Bool) {
        connectingView.isHidden = state != .onlineSynchronizing
        connectingView.animating = state == .onlineSynchronizing
        offlineView.isHidden = state != .offlineExpanded && state != .offlineCollapsed

        if state == .online || state == .onlineSynchronizing {
            offlineView.state = .minimized
        }

        var offlineBarState: OfflineBarState?
        switch state {
        case .offlineExpanded:
            offlineBarState = .expanded
        case .offlineCollapsed:
            offlineBarState = .minimized
        default:
            offlineBarState = nil
        }

        if let offlineBarState = offlineBarState {
            if animated {
                UIView.animate(withDuration: NetworkStatusView.resizeAnimationTime, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                    self.offlineView.update(state: offlineBarState, animated: animated)
                    self.layoutIfNeeded()
                })
            } else {
                self.offlineView.update(state: offlineBarState, animated: animated)
            }

            delegate?.didChangeHeight(self, animated: animated, offlineBarState: offlineBarState)
        }

    }

    // Detects when the view can be touchable
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return state == .offlineExpanded
    }
}

