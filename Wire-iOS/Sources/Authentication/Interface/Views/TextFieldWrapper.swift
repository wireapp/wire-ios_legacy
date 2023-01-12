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

import Foundation
import UIKit

final class TextFieldWrapper: UIView {
    var label: DynamicFontLabel

    var textField: ValidatedTextField

    init(label: String, textFieldBuilder: () -> ValidatedTextField, placeholder: String) {
        self.label = DynamicFontLabel(text: label, fontSpec: .subheadlineFont, color: SemanticColors.Label.textFieldFloatingLabel)
        textField = textFieldBuilder()
        textField.placeholder = placeholder
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let views: [UIView] = [label, textField]
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview($0)
            $0.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        }

        label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2).isActive = true
        textField.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}
