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

class Label: UIView, DynamicTypeCapable {

    private let label: UILabel
    private let fontSpec: FontSpec

    init(
        key: String? = nil,
        size: FontSize = .normal,
        weight: FontWeight = .regular,
        color: ColorSchemeColor,
        variant: ColorSchemeVariant = ColorScheme.default.variant
    ) {
        fontSpec = FontSpec(size, weight)
        label = UILabel(frame: .zero)
        label.text = key.map { $0.localized }
        label.font = fontSpec.font
        label.textColor = UIColor.from(scheme: color, variant: variant)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)

        addSubview(label)
        label.fitIn(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var numberOfLines: Int {
        get {
            label.numberOfLines
        }
        set {
            label.numberOfLines = newValue
        }

    }

    var textAlignment: NSTextAlignment {
        get {
            label.textAlignment
        }
        set {
            label.textAlignment = newValue
        }

    }

    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }

    }

    func redrawFont() {
        label.font = fontSpec.font
    }

}
