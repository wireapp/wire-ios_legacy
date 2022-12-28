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
import WireCommonComponents

protocol LocationSendViewControllerDelegate: AnyObject {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

final class LocationSendViewController: UIViewController {

    let sendButton = Button(style: .accentColorTextButtonStyle, cornerRadius: 12, fontSpec: .normalSemiboldFont)

    let addressLabel: UILabel = {
        let label = DynamicFontLabel(fontSpec: FontSpec.normalFont, color: SemanticColors.Label.textDefault)
        label.numberOfLines = 0
        return label
    }()

    private let containerView = UIView()

    weak var delegate: LocationSendViewControllerDelegate?

    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        createConstraints()

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    fileprivate func configureViews() {
        sendButton.setTitle("location.send_button.title".localized, for: [])
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
        addressLabel.accessibilityIdentifier = "selectedAddress"
        view.addSubview(containerView)
        [addressLabel, sendButton].forEach(containerView.addSubview)
    }

    private func createConstraints() {
        [containerView, addressLabel, sendButton].prepareForLayout()
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -12),
            addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        sendButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }

    @objc
    private func sendButtonTapped(_ sender: LegacyButton) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
