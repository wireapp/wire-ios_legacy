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
    
    private var pinnedItem = ConversationListPinnedItemView()
    private var pinnedItemHeight: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if ZMUser.selfUser().isTeamMember {
            let availabilityView = AvailabilityTitleView(user: ZMUser.selfUser(), style: .header)
            availabilityView.tapHandler = { button in
                let alert = availabilityView.actionSheet
                alert.popoverPresentationController?.sourceView = button
                alert.popoverPresentationController?.sourceRect = button.frame
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            self.middleView = availabilityView
        } else {
            let titleLabel = UILabel()
            
            titleLabel.font = FontSpec(.normal, .semibold).font
            titleLabel.textColor = ColorScheme.default().color(withName: ColorSchemeColorTextForeground, variant: .dark)
            titleLabel.text = ZMUser.selfUser().name
            titleLabel.accessibilityTraits = UIAccessibilityTraitHeader
            titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
            titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
            self.middleView = titleLabel
        }
        
        self.splitSeparator = false
        
        self.addSubview(pinnedItem)
        
        constrain(self, containerView, pinnedItem) { (selfView, containerView, pinnedItem) in
            containerView.bottom == pinnedItem.top
            pinnedItem.left == selfView.left
            pinnedItem.right == selfView.right
            pinnedItem.bottom == selfView.bottom
            pinnedItemHeight = pinnedItem.height == 0.0
        }
        
        self.containerViewBottomConstraint.isActive = false
        
    }
    
    
    func pinConversations(_ conversations: [ZMConversation]?) {
        guard let conversations = conversations else { unpinConversations(); return }
        self.pinnedItem.items = conversations
        self.pinnedItem.isHidden = false
        self.pinnedItemHeight?.constant = heightForPinnedItems(count: conversations.count)
        invalidateIntrinsicContentSize()
    }
    
    func unpinConversations() {
        self.pinnedItem.items = nil
        self.pinnedItem.isHidden = true
        self.pinnedItemHeight?.constant = 0.0
        invalidateIntrinsicContentSize()
    }
    
    override open var intrinsicContentSize: CGSize {
        let defaultHeight: CGFloat = 44.0
        guard let conversations = self.pinnedItem.items, conversations.count > 0 else { return CGSize(width: UIViewNoIntrinsicMetric, height: defaultHeight) }
        return CGSize(width: UIViewNoIntrinsicMetric, height: defaultHeight + heightForPinnedItems(count: conversations.count))
    }
    
    private func heightForPinnedItems(count: Int) -> CGFloat {
        return ConversationListItemViewCellHeight * CGFloat(count)
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
    
    internal var containerView = UIView()
    
    public var leftView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = leftView else {
                return
            }
            
            containerView.addSubview(new)
            
            constrain(containerView, new) { containerView, new in
                new.leading == containerView.leadingMargin
                new.centerY == containerView.centerY
            }
        }
    }
    
    public var rightView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = rightView else {
                return
            }
            
            containerView.addSubview(new)
            
            constrain(containerView, new) { containerView, new in
                new.trailing == containerView.trailingMargin
                new.centerY == containerView.centerY
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
    internal var containerViewBottomConstraint: NSLayoutConstraint!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutMargins = UIEdgeInsetsMake(0, 16, 0, 16)
        containerView.backgroundColor = .clear
        self.addSubview(containerView)
        [leftSeparatorLineView, rightSeparatorLineView, middleViewContainer].forEach(containerView.addSubview)
        
        constrain(self, self.containerView, self.middleViewContainer, self.leftSeparatorLineView, self.rightSeparatorLineView) {
            selfView, containerView, middleViewContainer, leftSeparatorLineView, rightSeparatorLineView in
            
            leftSeparatorLineView.leading == selfView.leading
            leftSeparatorLineView.bottom == selfView.bottom
            
            rightSeparatorLineView.trailing == selfView.trailing
            rightSeparatorLineView.bottom == selfView.bottom
            
            middleViewContainer.center == containerView.center
            leftSeparatorLineView.trailing == selfView.centerX ~ LayoutPriority(750)
            rightSeparatorLineView.leading == selfView.centerX ~ LayoutPriority(750)
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 7
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 7
            
            self.containerViewBottomConstraint = containerView.bottom == selfView.bottom
            containerView.left == selfView.left
            containerView.right == selfView.right
            containerView.top == selfView.top
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
}
