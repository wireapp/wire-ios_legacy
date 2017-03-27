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

public class RoundedTextBadge: RoundedBadge {
    public var textLabel = UILabel()

    init() {
        super.init(view: self.textLabel)
        textLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        textLabel.textAlignment = .center
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class RoundedBadge: UIView {
    public let containedView: UIView
    init(view: UIView) {
        containedView = view
        super.init(frame: .zero)
        
        self.addSubview(containedView)
        
        constrain(self, containedView) { selfView, containedView in
            containedView.leading == selfView.leading + 4
            containedView.trailing == selfView.trailing - 4
            containedView.top == selfView.top + 2
            containedView.bottom == selfView.bottom - 2
            
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
