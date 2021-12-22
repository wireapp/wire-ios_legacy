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
import WireCommonComponents

extension IconButton {

    static let width: CGFloat = 64
    static let height: CGFloat = 64

    static func acceptCall() -> IconButton {
        return .init(
            icon: .phone,
            accessibilityId: "AcceptButton",
            backgroundColor: [.normal: UIColor.strongLimeGreen],
            iconColor: [.normal: .white],
            width: IconButton.width
        )
    }

    static func endCall() -> IconButton {
        return .init(
            icon: .endCall,
            size: .small,
            accessibilityId: "LeaveCallButton",
            backgroundColor: [.normal: UIColor.vividRed],
            iconColor: [.normal: .white],
            width: IconButton.width
        )
    }

    static func sendButton() -> IconButton {

        let sendButtonIconColor = UIColor.from(scheme: .background, variant: .light)

        let sendButton = IconButton(
            icon: .send,
            accessibilityId: "sendButton",
            backgroundColor: [.normal: UIColor.accent(),
                              .highlighted: UIColor.accentDarken],
            iconColor: [.normal: sendButtonIconColor,
                        .highlighted: sendButtonIconColor,
                        .disabled: sendButtonIconColor,
                        .selected: sendButtonIconColor]
        )

        sendButton.adjustsImageWhenHighlighted = false
        sendButton.adjustBackgroundImageWhenHighlighted = true

        return sendButton
    }

    fileprivate convenience init(
        icon: StyleKitIcon,
        size: StyleKitIcon.Size = .tiny,
        accessibilityId: String,
        backgroundColor: [UIControl.State: UIColor],
        iconColor: [UIControl.State: UIColor],
        width: CGFloat? = nil
        ) {
        self.init()
        circular = true
        setIcon(icon, size: size, for: .normal)
        titleLabel?.font = FontSpec(.small, .light).font!
        accessibilityIdentifier = accessibilityId
        translatesAutoresizingMaskIntoConstraints = false

        for (state, color) in backgroundColor {
            setBackgroundImageColor(color, for: state)
        }

        for (state, color) in iconColor {
            setIconColor(color, for: state)
        }

        borderWidth = 0

        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
            heightAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        }
    }

}

extension UIControl.State: Hashable {
    public var hashValue: Int {
        return Int(self.rawValue)
    }
}
