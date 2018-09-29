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

extension TokenField {
    @objc func setupStyle() {
        tokenOffset = 4

        textView.tintColor = .accent()
        textView.autocorrectionType = .no
        textView.returnKeyType = .go
        textView.placeholderFont = .smallRegularFont
        textView.placeholderTextContainerInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        textView.placeholderTextTransform = .upper
        textView.lineFragmentPadding = 0
    }

    @objc func setupFonts() {
        // Dynamic Type is disabled for now until the separator dots
        // vertical alignment has been fixed for larger fonts.
        let schema = FontScheme(contentSizeCategory: .medium)
        font = schema.font(for: .init(.normal, .regular))
        tokenTitleFont = schema.font(for: .init(.small, .regular))
    }
}
