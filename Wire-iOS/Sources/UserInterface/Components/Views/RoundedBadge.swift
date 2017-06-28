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

public class RoundedBadge: UIView {
    public let containedView: UIView
    init(view: UIView, contentInset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)) {
        containedView = view
        super.init(frame: .zero)
        
        self.addSubview(containedView)
        
        constrain(self, containedView) { selfView, containedView in
            containedView.leading == selfView.leading + contentInset.left
            containedView.trailing == selfView.trailing - contentInset.right
            containedView.top == selfView.top + contentInset.top
            containedView.bottom == selfView.bottom - contentInset.bottom
            
            selfView.width >= selfView.height
        }
        
        self.layer.masksToBounds = true
        updateCornerRadius()
    }
    
    func updateCornerRadius() {
        self.layer.cornerRadius = ceil(self.bounds.height / 2.0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
}

public class RoundedTextBadge: RoundedBadge {
    public var textLabel = UILabel()
    
    init(contentInset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)) {
        super.init(view: self.textLabel, contentInset: contentInset)
        textLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        textLabel.textAlignment = .center
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class GuestLabel: RoundedTextBadge {
    init() {
        super.init(contentInset: UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8))
        textLabel.text = "participants.avatar.guest.title".localized
        accessibilityIdentifier = "guest label"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

