//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

enum OutgoingConnectionBottomBarAction: UInt {
    case cancel, archive
}

final class OutgoingConnectionViewController: UIViewController {

    private let cancelButton = IconButton(style: .default)
    private let archiveButton = IconButton(style: .default)

    var buttonCallback: ((OutgoingConnectionBottomBarAction) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupCancelButton()
        setupArchiveButton()
        [cancelButton, archiveButton].forEach(view.addSubview)
    }

    private func setupCancelButton() {
        cancelButton.accessibilityLabel = "cancel connection"
        cancelButton.setIcon(.undo, size: .tiny, for: .normal)
        cancelButton.setTitle("profile.cancel_connection_button_title".localized(uppercased: true), for: .normal)
        cancelButton.titleLabel?.font = FontSpec(.small, .light).font!
        cancelButton.setTitleColor(UIColor.from(scheme: .textForeground), for: .normal)
        cancelButton.setTitleImageSpacing(24)
        cancelButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func setupArchiveButton() {
        archiveButton.accessibilityLabel = "archive connection"
        archiveButton.setIcon(.archive, size: .tiny, for: .normal)
        archiveButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func createConstraints() {
        [cancelButton, archiveButton].prepareForLayout()
        NSLayoutConstraint.activate([
          cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
          cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
          cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
          archiveButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
          archiveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func buttonTapped(sender: IconButton) {
        switch sender {
        case cancelButton: buttonCallback?(.cancel)
        case archiveButton: buttonCallback?(.archive)
        default: break
        }
    }

}
