//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension IconButton {
    
    static let width: CGFloat = 64
    static let height: CGFloat = 64
    
    static func acceptCall() -> IconButton {
        return .init(
            icon: .phone,
            accessibilityId: "AcceptButton",
            backgroundColor: ZMAccentColor.strongLimeGreen.color,
            iconColor: .white
        )
    }
    
    static func endCall() -> IconButton {
        return .init(
            icon: .endCall,
            size: .small,
            accessibilityId: "LeaveCallButton",
            backgroundColor: ZMAccentColor.vividRed.color,
            iconColor: .white
        )
    }
    
    fileprivate convenience init(
        icon: ZetaIconType,
        size: ZetaIconSize = .tiny,
        accessibilityId: String,
        backgroundColor: UIColor,
        iconColor: UIColor
        ) {
        self.init()
        circular = true
        setIcon(icon, with: size, for: .normal)
        titleLabel?.font = FontSpec(.small, .light).font!
        accessibilityIdentifier = accessibilityId
        translatesAutoresizingMaskIntoConstraints = false
        setBackgroundImageColor(backgroundColor, for: .normal)
        setIconColor(iconColor, for: .normal)
        borderWidth = 0
        widthAnchor.constraint(equalToConstant: IconButton.width).isActive = true
        heightAnchor.constraint(greaterThanOrEqualToConstant: IconButton.width).isActive = true
    }
    
}
