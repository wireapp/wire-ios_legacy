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

@objc final public class NoResultsView: UIView {
    public let label = UILabel()
    private let iconView = UIImageView()
    
    public var icon: ZetaIconType = .none {
        didSet {
            self.iconView.image = UIImage(for: icon, fontSize: 160, color: placeholderColor)
        }
    }
    
    public var placeholderColor: UIColor {
        let backgroundColor = ColorScheme.default().color(withName: ColorSchemeColorBackground)
        let placeholderColor = backgroundColor.mix(ColorScheme.default().color(withName: ColorSchemeColorTextForeground), amount: 0.16)
        return placeholderColor!
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isAccessibilityElement = true
        self.accessibilityElements = [self.label]
        
        self.label.numberOfLines = 0
        self.label.textColor = placeholderColor
        self.label.textAlignment = .center
        self.addSubview(self.label)
        
        self.iconView.contentMode = .scaleAspectFit
        self.addSubview(self.iconView)
        
        constrain(self, self.label, self.iconView) { selfView, label, iconView in
            iconView.top == selfView.top
            iconView.centerX == selfView.centerX
            
            label.top == iconView.bottom + 24
            label.bottom == selfView.bottom
            label.leading == selfView.leading
            label.trailing == selfView.trailing
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatal("init?(coder:) is not implemented")
    }
}
