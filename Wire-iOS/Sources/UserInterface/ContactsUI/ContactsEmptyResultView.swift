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

final class ContactsEmptyResultView: UIView {
    @objc let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.from(scheme: .textForeground, variant: .dark)

        return label
    }()

    @objc let actionButton: Button = Button(style: .full)

    private let containerView = UIView()

    init() {
        super.init(frame: .zero)
        setupViews()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(containerView)

        containerView.addSubview(messageLabel)
        containerView.addSubview(actionButton)
    }

    private func setupLayout() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(

                                    messageLabel.fitInSuperview(exclude:[.bottom]).values.map{ $0 } +
                                    actionButton.fitInSuperview(exclude:[.top]).values.map{ $0 } +

                                    [actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
                                     actionButton.heightAnchor.constraint(equalToConstant: 28)] +

                                    containerView.centerInSuperview())
    }

}
