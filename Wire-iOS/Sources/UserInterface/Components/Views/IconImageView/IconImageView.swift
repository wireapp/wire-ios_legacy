//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireCommonComponents

protocol IconImageStyle {
    var icon: StyleKitIcon? { get }
    var tintColor: UIColor? { get }
}

extension IconImageStyle {
    var tintColor: UIColor? {
        return nil
    }
}

class IconImageView: UIImageView {
    private(set) var size: StyleKitIcon.Size = .tiny
    private(set) var color: UIColor = UIColor.from(scheme: .iconGuest)
    
    func set(style: IconImageStyle) {
        guard let icon = style.icon else {
            isHidden = true; return
        }
        
        isHidden = false
        let color = style.tintColor ?? self.color
        self.setIcon(icon, size: size, color: color)
    }
    
    func set(iconSize size: StyleKitIcon.Size, color: UIColor) {
        self.size = size
        self.color = color
    }
}
