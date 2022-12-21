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

class CallHeaderBar: UIView {
    private let titleLabel = DynamicFontLabel(fontSpec: .normalSemiboldFont, color:  SemanticColors.Label.textDefault)
    let minimalizeButton = UIButton()

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = SemanticColors.View.backgroundDefault
        minimalizeButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        minimalizeButton.tintColor = SemanticColors.View.backgroundDefaultBlack
        [minimalizeButton, titleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(titleLabel)
        addSubview(minimalizeButton) 
        titleLabel.accessibilityTraits = .header
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 14.0),
            minimalizeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            minimalizeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 14.0),
            minimalizeButton.widthAnchor.constraint(equalToConstant: 32.0),
            minimalizeButton.heightAnchor.constraint(equalToConstant: 32.0),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: minimalizeButton.trailingAnchor, constant: 6.0)
        ])
    }
    

    func setTitle(title: String) {
        titleLabel.text = title
    }
}
