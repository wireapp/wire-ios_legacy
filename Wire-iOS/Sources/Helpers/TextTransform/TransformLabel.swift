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

/**
 * A label that can automatically transform the text it presents.
 */

final class TransformLabel: UILabel {

    override var accessibilityValue: String? {
        set {
            super.accessibilityValue = newValue
        }

        get {
            return attributedText?.string ?? text
        }
    }

    /// The transform to apply to the text.
    var textTransform: TextTransform = .none {
        didSet {
            attributedText = attributedText?.applying(transform: textTransform)
        }
    }

    override var text: String? {
        get {
            return super.text
        }
        set {
            super.text = newValue?.applying(transform: textTransform)
        }
    }

    override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            super.attributedText = newValue?.applying(transform: textTransform)
        }
    }

}
