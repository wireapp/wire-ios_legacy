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
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        let titleLabel = UILabel()
        
        titleLabel.font = FontSpec(.medium, .semibold).font
        titleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
        titleLabel.text = "list.title".localized.uppercased()
        titleLabel.accessibilityTraits = UIAccessibilityTraitHeader
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.middleView = titleLabel
        
        self.splitSeparator = false
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 7
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 7
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
}
