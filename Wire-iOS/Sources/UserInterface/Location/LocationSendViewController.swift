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

protocol LocationSendViewControllerDelegate: class {
    func locationSendViewControllerSendButtonTapped(_ viewController: LocationSendViewController)
}

final class LocationSendViewController: UIViewController {

    let sendButton = Button(style: .full)
    public let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .normalFont
        label.textColor = .from(scheme: .textForeground)
        return label
    }()
    public let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.from(scheme: .separator)
        return view
    }()
    fileprivate let containerView = UIView()

    weak var delegate: LocationSendViewControllerDelegate?

    var address: String? {
        didSet {
            addressLabel.text = address
        }
    }

    public override func viewDidLoad() {
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

    fileprivate func createConstraints() {
        [<#views#>].prepareForLayout()
        NSLayoutConstraint.activate([
          container.topAnchor.constraint(equalTo: inset(view.topAnchor),
          container.bottomAnchor.constraint(equalTo: inset(view.bottomAnchor),
          container.leftAnchor.constraint(equalTo: inset(view.leftAnchor),
          container.rightAnchor.constraint(equalTo: inset(view.rightAnchor),
          label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
          label.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -12 ~ 1000.0),
          label.topAnchor.constraint(equalTo: container.topAnchor),
          label.bottomAnchor.constraint(equalToConstant: container.bottom - UIScreen.safeArea.bottom),
          button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
          button.centerYAnchor.constraint(equalTo: label.centerYAnchor),
          button.heightAnchor.constraint(equalToConstant: 28),
          separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          separator.topAnchor.constraint(equalTo: container.topAnchor),
          separator.heightAnchor.constraint(equalTo: .hairlineAnchor)
        ])

        sendButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }

    @objc fileprivate func sendButtonTapped(_ sender: Button) {
        delegate?.locationSendViewControllerSendButtonTapped(self)
    }
}
