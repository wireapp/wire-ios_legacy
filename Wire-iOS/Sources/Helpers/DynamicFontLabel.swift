//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// A helper class that provides the label with Dynamic Type Support
/// by conforming to the DynamicTypeCapable Protocol.
class DynamicFontLabel: UILabel, DynamicTypeCapable {

    // MARK: - Properties
    private let fontSpec: FontSpec

    // MARK: - initialization
    init(
        text: String? = nil,
        fontSpec: FontSpec = .normalRegularFont,
        color: ColorSchemeColor,
        variant: ColorSchemeVariant = ColorScheme.default.variant
    ) {
        self.fontSpec = fontSpec
        super.init(frame: .zero)

        self.text = text
        self.font = fontSpec.font
        self.textColor = UIColor.from(scheme: color, variant: variant)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods
    func redrawFont() {
        self.font = fontSpec.font
    }

}
