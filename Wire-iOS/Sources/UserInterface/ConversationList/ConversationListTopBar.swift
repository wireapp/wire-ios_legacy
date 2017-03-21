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
    
    public var middleView: UIView? = .none {
        didSet {
            oldValue?.removeFromSuperview()
            
            guard let new = middleView else {
                return
            }
            
            self.addSubview(new)
            
            constrain(self, new) { selfView, new in
                new.center == selfView.center
            }
        }
    }
    
    public let separatorLineView = OverflowSeparatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.separatorLineView)
        
        constrain(self, self.separatorLineView) { selfView, separatorLineView in
            separatorLineView.leading == selfView.leading
            separatorLineView.trailing == selfView.trailing
            separatorLineView.bottom == selfView.bottom
            separatorLineView.height == .hairline
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 44)
    }
}
