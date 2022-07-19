//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import Foundation

class FolderCreationNameCell: UICollectionViewCell {

    let textField = SimpleTextField()

    var variant: ColorSchemeVariant = ColorScheme.default.variant {
        didSet {
            guard oldValue != variant else { return }
            configureColors()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    fileprivate func setup() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isAccessibilityElement = true
        textField.accessibilityIdentifier = "textfield.newfolder.name"
        textField.placeholder = "folder.creation.name.placeholder".localized(uppercased: true)

        contentView.addSubview(textField)
        textField.fitIn(view: contentView)

        configureColors()
    }

    private func configureColors() {
        backgroundColor = UIColor.from(scheme: .barBackground, variant: variant)
        textField.applyColorScheme(variant)
    }
}
