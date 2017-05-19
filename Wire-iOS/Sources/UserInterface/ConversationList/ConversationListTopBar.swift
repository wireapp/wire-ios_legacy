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

import UIKit
import Cartography
import WireExtensionComponents

final class ConversationListTopBar: TopBar {
    private var teamsView: TeamSelectorView? = .none
    public weak var contentScrollView: UIScrollView? = .none
    
    public enum ImagesState: Int {
        case collapsed
        case visible
    }

    private var state: ImagesState = .visible
   
    public func update(to newState: ImagesState, animated: Bool = false, force: Bool = false) {
        if !force && (self.state == newState || self.teams.isEmpty) {
            return
        }
        
        self.state = newState
        let change = {
            self.teamsView?.imagesCollapsed = self.state == .collapsed
            self.splitSeparator = self.state == .visible
        }
        
        if animated {
            UIView.wr_animate(easing: RBBEasingFunctionEaseOutExpo, duration: 0.35, animations: change)
        }
        else {
            change()
        }
    }
    
    internal var teams: [TeamType] = [] {
        didSet {
            self.setShowTeams(to: !teams.isEmpty)
        }
    }
    
    fileprivate var showTeams: Bool = false
    
    private func setShowTeams(to showTeams: Bool) { // TODO: SMB: Observe teams in order to show / hide teamsView
        self.showTeams = showTeams
        UIView.performWithoutAnimation {
            if showTeams {
                self.teamsView?.removeFromSuperview()
                self.teamsView = TeamSelectorView()
                self.teamsView?.update(with: teams) // TODO: SMB: remove in favor of CoreData observation, also make private
                self.middleView = self.teamsView
                self.leftSeparatorLineView.alpha = 1
                self.rightSeparatorLineView.alpha = 1
                
                let topOffset: CGFloat = self.contentScrollView?.contentOffset.y ?? 0.0
                let scrolledOffFromTop: Bool = topOffset > 0.0
                let state: ImagesState = scrolledOffFromTop ? .collapsed : .visible
                self.update(to: state, force: true)
                
                self.contentScrollView?.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
                if !scrolledOffFromTop {
                    self.contentScrollView?.contentOffset = CGPoint(x: 0, y: -16)
                }
            }
            else {
                let titleLabel = UILabel()
                
                titleLabel.font = FontSpec(.medium, .semibold).font
                titleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground,
                                                                   variant: .dark)
                titleLabel.text = "list.title".localized.uppercased()
                titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
                titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
                titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
                titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
                self.middleView = titleLabel
                
                self.contentScrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                self.splitSeparator = false
            }
        }
        if let contentScrollView = self.contentScrollView {
            self.scrollViewDidScroll(scrollView: contentScrollView)
        }
    }
}

extension ConversationListTopBar {
    @objc(scrollViewDidScroll:)
    public func scrollViewDidScroll(scrollView: UIScrollView!) {
        
        let state: ImagesState = scrollView.contentOffset.y > 0 ? .collapsed : .visible
        
        self.update(to: state, animated: true)
        
        if !self.showTeams {
            self.leftSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
            self.rightSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
        }
    }
}

open class TopBar: UIView {
    public var leftView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = leftView else {
                return
            }
            
            self.addSubview(new)
            
            constrain(self, new) { selfView, new in
                new.leading == selfView.leading + 16
                new.centerY == selfView.centerY
            }
        }
    }
    
    public var rightView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = rightView else {
                return
            }
            
            self.addSubview(new)
            
            constrain(self, new) { selfView, new in
                new.trailing == selfView.trailing - 16
                new.centerY == selfView.centerY
            }
        }
    }
    
    private let middleViewContainer = UIView()
    
    public var middleView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = middleView else {
                return
            }
            
            self.middleViewContainer.addSubview(new)
            
            constrain(middleViewContainer, new) { middleViewContainer, new in
                new.center == middleViewContainer.center
                middleViewContainer.size == new.size
            }
        }
    }
    
    public var splitSeparator: Bool = true {
        didSet {
            leftSeparatorInsetConstraint.isActive = splitSeparator
            rightSeparatorInsetConstraint.isActive = splitSeparator
            self.layoutIfNeeded()
        }
    }
    
    public let leftSeparatorLineView = OverflowSeparatorView()
    public let rightSeparatorLineView = OverflowSeparatorView()
    
    private var leftSeparatorInsetConstraint: NSLayoutConstraint!
    private var rightSeparatorInsetConstraint: NSLayoutConstraint!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        [leftSeparatorLineView, rightSeparatorLineView, middleViewContainer].forEach(self.addSubview)
        
        constrain(self, self.middleViewContainer, self.leftSeparatorLineView, self.rightSeparatorLineView) {
            selfView, middleViewContainer, leftSeparatorLineView, rightSeparatorLineView in
            
            leftSeparatorLineView.leading == selfView.leading
            leftSeparatorLineView.bottom == selfView.bottom
            
            rightSeparatorLineView.trailing == selfView.trailing
            rightSeparatorLineView.bottom == selfView.bottom
            
            middleViewContainer.center == selfView.center
            leftSeparatorLineView.trailing == selfView.centerX ~ LayoutPriority(750)
            rightSeparatorLineView.leading == selfView.centerX ~ LayoutPriority(750)
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 16
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 16
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
}
