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

final class NotSignedInViewController: UIViewController {

    var closeHandler : (() -> Void)?

    let messageLabel = UILabel()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "share_extension.not_signed_in.close_button".localized,
            style: .done,
            target: self,
            action: #selector(onCloseTapped)
        )

        messageLabel.text = "share_extension.not_signed_in.title".localized
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        view.addSubview(messageLabel)

        createConstraints()
    }

    private func createConstraints() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            messageLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            messageLabel.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    @objc
    private func onCloseTapped() {
        closeHandler?()
    }
}
