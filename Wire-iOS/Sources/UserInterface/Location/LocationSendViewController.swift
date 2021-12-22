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

protocol LocationSendViewControllerDelegate: AnyObject {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

final class LocationSendViewController: UIViewController {

    let sendButton = Button(style: .full)
    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .normalFont
        label.textColor = .from(scheme: .textForeground)
        return label
    }()
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator)
        return view
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

        view.backgroundColor = .from(scheme: .background)
    }

    fileprivate func configureViews() {
        sendButton.setTitle("location.send_button.title".localized(uppercased: true), for: [])
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.accessibilityIdentifier = "sendLocation"
        addressLabel.accessibilityIdentifier = "selectedAddress"
        view.addSubview(containerView)
        [addressLabel, sendButton, separatorView].forEach(containerView.addSubview)
    }

    private func createConstraints() {
        [containerView, separatorView, addressLabel, sendButton].prepareForLayout()
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
            containerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24),
            containerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            addressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            addressLabel.trailingAnchor.constraint(lessThanOrEqualTo: sendButton.leadingAnchor, constant: -12),
            addressLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            addressLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: addressLabel.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 28),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: .hairline)
        ])

        sendButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }

    @objc
    private func sendButtonTapped(_ sender: Button) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
