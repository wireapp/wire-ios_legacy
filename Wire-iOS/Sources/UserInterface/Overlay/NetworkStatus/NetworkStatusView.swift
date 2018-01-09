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

class OfflineBar : UIView {
    
    private let collapsedHeight : CGFloat = 2
    private let expandedHeight: CGFloat = 20
    
    private let offlineLabel : UILabel
    private var heightConstraint : NSLayoutConstraint?
    private var _state : OfflineBarState = .minimized
    
    var state : OfflineBarState {
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
        
        backgroundColor = UIColor(red: 1.0, green: 0.6863, blue: 0, alpha: 1)
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
            
            heightConstraint = containerView.height == collapsedHeight
        }
    }
    
    private func updateViews(animated: Bool = true) {
        heightConstraint?.constant = state == .expanded ? expandedHeight : collapsedHeight
        offlineLabel.alpha = state == .expanded ? 1 : 0
    }
    
}

enum NetworkStatusViewState {
    case online
    case onlineSynchronizing
    case offlineExpanded
    case offlineCollapsed
}

class NetworkStatusView : UIView {
    
    private let connectingView : BreathLoadingBar
    private let offlineView : OfflineBar
    private var _state : NetworkStatusViewState = .online
    
    var state : NetworkStatusViewState {
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
            containerView.height == 20
            
            offlineView.left == containerView.left
            offlineView.right == containerView.right
            offlineView.top == containerView.top
            offlineView.bottom <= containerView.bottom
            
            connectingView.left == containerView.left
            connectingView.right == containerView.right
            connectingView.top == containerView.top
            connectingView.bottom <= containerView.bottom
            connectingView.height == 2
        }
    }
    
    func updateViewState(animated: Bool) {
        connectingView.isHidden = state != .onlineSynchronizing
        connectingView.animating = state == .onlineSynchronizing
        offlineView.isHidden = state != .offlineExpanded && state != .offlineCollapsed
        
        if state == .online || state == .onlineSynchronizing {
            offlineView.state = .minimized
        }
        
        if state == .offlineExpanded {
            if animated {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                    self.offlineView.update(state: .expanded, animated: animated)
                    self.layoutIfNeeded()
                })
            } else {
                self.offlineView.update(state: .expanded, animated: animated)
            }
        }
            
        if state == .offlineCollapsed {
            if animated {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    self.offlineView.update(state: .minimized, animated: animated)
                    self.layoutIfNeeded()
                })
            } else {
                self.offlineView.update(state: .minimized, animated: animated)
            }
        }
    }
    
    // Detects when the view can be touchable
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return state == .offlineExpanded
    }
}
