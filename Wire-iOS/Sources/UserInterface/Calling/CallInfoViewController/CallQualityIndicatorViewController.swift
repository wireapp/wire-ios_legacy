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

class CallQualityIndicatorViewController: UIViewController {

    // MARK: - Properties

    private let padding = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
    private let spacing: CGFloat = 16

    // MARK: - Components

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Your calling relay is not reachable. This may affect your call experience.".uppercased()
        label.font = FontSpec(.small, .medium).font!
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private let dismissButton: IconButton = {
        let button = IconButton(style: .default)
        button.setIcon(.cross, size: .tiny, for: .normal)
        button.setIconColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didTapDismissButton), for: .touchUpInside)
        return button
    }()

    private let moreInfoButton: Button = {
        let button = Button(style: .empty)
        button.setTitle("More info", for: .normal)
        button.textTransform = .none
        button.setTitleColor(.white, for: .normal)
        button.setBorderColor(UIColor(white: 1, alpha: 0.2), for: .normal)
        button.addTarget(self, action: #selector(didTapMoreInfoButton), for: .touchUpInside)
        return button
    }()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
    }

    // MARK: - Helpers

    private func setUpViews() {
        view.backgroundColor = UIColor(rgb: (196, 75, 70))
        view.layer.cornerRadius = 5
        view.clipsToBounds = true

        for subview in [messageLabel, dismissButton, moreInfoButton] {
            view.addSubview(subview)
        }
    }

    private func setUpConstraints() {
        for subview in [messageLabel, dismissButton, moreInfoButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: padding.top),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding.trailing)
        ])

        NSLayoutConstraint.activate([
            moreInfoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding.trailing),
            moreInfoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding.bottom)
        ])

        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        messageLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding.leading),
            messageLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding.top),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor, constant: -spacing),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: moreInfoButton.topAnchor, constant: -spacing)
        ])
    }

    // MARK: - Actions

    @objc
    private func didTapDismissButton() {

    }

    @objc private func didTapMoreInfoButton() {

    }

}
