//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

class CallInfoErrorView: UIView {
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.accessibilityIdentifier = "CallErrorLabel"
        return label
    }()
    
    private let closeButton: IconButton = {
        let button = IconButton(style: .default)
        button.setIcon(.cross, size: .tiny, for: .normal)
        button.setIconColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "CallErrorCloseButton"
        button.accessibilityLabel = "general.close".localized
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .vividRed
        layer.cornerRadius = 4
        closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        addSubview(closeButton)
        addSubview(errorLabel)
    }
    
    private func createConstraints() {
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 13),
            closeButton.heightAnchor.constraint(equalToConstant: 13),
            errorLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            errorLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            errorLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }
    
    func show(message: String) {
        errorLabel.text = message
        accessibilityLabel = message
        isHidden = false
    }
    
    @objc func hide() {
        isHidden = true
    }
}
