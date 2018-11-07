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
   
    internal var observerToken: Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if ZMUser.selfUser().isTeamMember {
            let availabilityView = AvailabilityTitleView(user: ZMUser.selfUser(), style: .header)
            availabilityView.tapHandler = { [weak availabilityView] button in
                guard let availabilityView = availabilityView else { return }
                
                let alert = availabilityView.actionSheet
                alert.popoverPresentationController?.sourceView = button
                alert.popoverPresentationController?.sourceRect = button.frame
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            self.middleView = availabilityView
        } else {
            let titleLabel = UILabel()
            
            titleLabel.font = FontSpec(.normal, .semibold).font
            titleLabel.textColor = UIColor.from(scheme: .textForeground, variant: .dark)
            titleLabel.accessibilityTraits = .header
            titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            titleLabel.setContentHuggingPriority(.required, for: .vertical)
            self.middleView = titleLabel
            
            if let sharedSession = ZMUserSession.shared() {
                self.observerToken = UserChangeInfo.add(observer: self, for: ZMUser.selfUser(), userSession: sharedSession)
            }
            
            updateMiddleViewTitle()
        }
        
        self.splitSeparator = false
    }
    
    func updateMiddleViewTitle() {
        guard let middleView = middleView as? UILabel else { return }
        middleView.text = ZMUser.selfUser().name
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ConversationListTopBar: ZMUserObserver {
    
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.nameChanged else { return }
        updateMiddleViewTitle()
    }
}

extension ConversationListTopBar {
    @objc(scrollViewDidScroll:)
    public func scrollViewDidScroll(scrollView: UIScrollView!) {
        self.leftSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
        self.rightSeparatorLineView.scrollViewDidScroll(scrollView: scrollView)
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
                new.leading == selfView.leadingMargin
                new.centerY == selfView.centerY
            }

            if let middleView = middleView {
                NSLayoutConstraint.activate([
                    new.trailingAnchor.constraint(lessThanOrEqualTo: middleView.leadingAnchor, constant: 0)
                    ])
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
                new.trailing == selfView.trailingMargin
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
        self.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        [leftSeparatorLineView, rightSeparatorLineView, middleViewContainer].forEach(self.addSubview)
        
        constrain(self, self.middleViewContainer, self.leftSeparatorLineView, self.rightSeparatorLineView) {
            selfView, middleViewContainer, leftSeparatorLineView, rightSeparatorLineView in
            
            leftSeparatorLineView.leading == selfView.leading
            leftSeparatorLineView.bottom == selfView.bottom
            
            rightSeparatorLineView.trailing == selfView.trailing
            rightSeparatorLineView.bottom == selfView.bottom
            
            middleViewContainer.center == selfView.center
            leftSeparatorLineView.trailing == selfView.centerX ~ 750.0
            rightSeparatorLineView.leading == selfView.centerX ~ 750.0
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 7
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 7
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }
}
