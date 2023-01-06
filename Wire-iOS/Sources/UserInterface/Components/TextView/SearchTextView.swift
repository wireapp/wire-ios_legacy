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

// A custom UITextView with applied styles for the search bar.
final class SearchTextView: TokenizedTextView {

    // MARK: - Properties

    private var style: SearchBarStyle?

    private var isEditing: Bool = false {
        didSet {
            guard let style = style else {
                return
            }
            layer.borderColor = isEditing
            ? style.borderColorSelected.resolvedColor(with: traitCollection).cgColor
            : style.borderColorNotSelected.cgColor
        }
    }

    // MARK: - initialization

    convenience init(style: SearchBarStyle) {
        self.init(frame: .zero)

        self.style = style
        applyStyle(style)
        configureObservers()
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing(_:)), name: UITextView.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidEndEditing(_:)), name: UITextView.textDidEndEditingNotification, object: self)
    }

    @objc
    func textViewDidBeginEditing(_ note: Notification?) {
        isEditing = true
    }

    @objc
    func textViewDidEndEditing(_ note: Notification?) {
        isEditing = false
    }

}
