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
import WireCommonComponents

final class InviteButton: IconButton {
    init(variant: ColorSchemeVariant = ColorScheme.default.variant) {
        super.init()

        clipsToBounds = true
        titleLabel?.font = FontSpec.normalSemiboldFont.font!
        applyStyle(.secondaryTextButtonStyle)
        layer.cornerRadius = 12
        contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
    }

    override var isHighlighted: Bool {
        didSet {
            applyStyle(.secondaryTextButtonStyle)
        }
    }
}
