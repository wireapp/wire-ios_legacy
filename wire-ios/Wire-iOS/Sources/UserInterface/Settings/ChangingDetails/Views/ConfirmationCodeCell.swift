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

import Foundation
import UIKit

class ConfirmationCodeCell: UITableViewCell {

    let textField: CharacterInputField = {
        let textField = CharacterInputField(maxLength: 6, characterSet: .decimalDigits, size: CGSize(width: 375, height: 56))
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
        createConstraints()

        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(textField)

        if #available(iOS 12, *) {
            textField.textContentType = .oneTimeCode
        }

        textField.keyboardType = .decimalPad
        textField.accessibilityIdentifier = "VerificationCode"
        textField.accessibilityLabel = "verification.code_label".localized
        textField.isAccessibilityElement = true
    }

    private func createConstraints() {
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 8)
        ])
    }

}
