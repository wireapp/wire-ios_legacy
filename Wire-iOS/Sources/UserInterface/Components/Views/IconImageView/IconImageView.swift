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
    var accessibilityIdentifier: String { get }
    var accessibilityPrefix: String { get }
    var accessibilitySuffix: String { get }
}

extension IconImageStyle {
    var accessibilityPrefix: String {
        return "img"
    }

    var accessibilityIdentifier: String {
        return "\(accessibilityPrefix).\(accessibilitySuffix)"
    }

    var tintColor: UIColor? {
        return nil
    }
}

class IconImageView: UIImageView {
    private(set) var size: StyleKitIcon.Size = .tiny
    private(set) var color: UIColor = UIColor.from(scheme: .iconGuest)
    private(set) var style: IconImageStyle?

    override init(frame: CGRect) {
        super.init(frame: frame)
        image = UIImage()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityIdentifier: String? {
        get {
            return style?.accessibilityIdentifier
        }
        set {
            // no-op
        }
    }

    func set(style: IconImageStyle? = nil,
             size: StyleKitIcon.Size? = nil,
             color: UIColor? = nil) {
        // save size and color if needed
        set(size: size, color: color)

        guard
            let style = style ?? self.style,
            let icon = style.icon
        else {
            isHidden = true
            return
        }

        isHidden = false
        let color = style.tintColor ?? self.color
        self.setIcon(icon, size: self.size, color: color)
        self.style = style
    }

    private func set(size: StyleKitIcon.Size?, color: UIColor?) {
        guard let size = size, let color = color else {
            return
        }

        self.size = size
        self.color = color
    }
}
