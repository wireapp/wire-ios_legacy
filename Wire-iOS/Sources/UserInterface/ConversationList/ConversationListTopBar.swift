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

final class ConversationListTopBar: UIView {
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
                new.edges == middleViewContainer.edges
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
        
        constrain(self, self.middleViewContainer, self.leftSeparatorLineView, self.rightSeparatorLineView) { selfView, middleViewContainer, leftSeparatorLineView, rightSeparatorLineView in
            leftSeparatorLineView.leading == selfView.leading
            leftSeparatorLineView.bottom == selfView.bottom
            
            rightSeparatorLineView.trailing == selfView.trailing
            rightSeparatorLineView.bottom == selfView.bottom
            
            middleViewContainer.center == selfView.center
            leftSeparatorLineView.trailing == selfView.trailing ~ LayoutPriority(750)
            rightSeparatorLineView.leading == selfView.leading ~ LayoutPriority(750)
            self.leftSeparatorInsetConstraint = leftSeparatorLineView.trailing == middleViewContainer.leading - 16
            self.rightSeparatorInsetConstraint = rightSeparatorLineView.leading == middleViewContainer.trailing + 16
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
}
