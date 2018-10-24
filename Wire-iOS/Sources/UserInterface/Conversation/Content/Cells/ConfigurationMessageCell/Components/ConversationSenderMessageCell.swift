//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let user: UserType
    }

    var isSelected: Bool = false
    private let senderView = SenderCellComponent()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    func configure(with object: Configuration) {
        senderView.configure(with: object.user)
    }

    private func configureSubviews() {
        addSubview(senderView)
    }

    private func configureConstraints() {
        senderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            senderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            senderView.topAnchor.constraint(equalTo: topAnchor),
            senderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            senderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}

class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSenderMessageCell
    let configuration: View.Configuration

    init(sender: UserType) {
        self.configuration = View.Configuration(user: sender)
    }
}
