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


import Foundation
import UIKit

public class GuestIndicator: UIImageView, Themeable {

    @objc dynamic var colorSchemeVariant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != colorSchemeVariant else { return }
            applyColorScheme(colorSchemeVariant)
        }
    }

    func applyColorScheme(_ colorSchemeVariant: ColorSchemeVariant) {
        setIcon(.guest, size: .tiny, color: UIColor.from(scheme: .iconGuest, variant: colorSchemeVariant))
    }

    init() {
        super.init(frame: .zero)
        contentMode = .scaleToFill
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        accessibilityIdentifier = "img.guest"
        applyColorScheme(colorSchemeVariant)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

