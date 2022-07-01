//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireDataModel
import UIKit

final class TextSearchResultFooter: UIView {
    var message: ZMConversationMessage? {
        didSet {
            guard let message = message, let serverTimestamp = message.serverTimestamp, let sender = message.senderUser else {
                return
            }

            nameLabel.textColor = sender.accentColor
            nameLabel.text = sender.name
            nameLabel.accessibilityValue = nameLabel.text

            dateLabel.text = serverTimestamp.formattedDate
            dateLabel.accessibilityValue = dateLabel.text
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatal("init(coder: NSCoder) is not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel.accessibilityLabel = "sender name"
        dateLabel.accessibilityLabel = "sent on"

        addSubview(nameLabel)
        addSubview(dateLabel)

        [nameLabel, dateLabel].prepareForLayout()
        NSLayoutConstraint.activate([
          nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
          nameLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -4),
          dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
          nameLabel.topAnchor.constraint(equalTo: topAnchor),
          nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
          dateLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor)
        ])
    }

    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .smallSemiboldFont

        return label
    }()

    var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .smallLightFont
        label.textColor = .from(scheme: .textDimmed)

        return label
    }()
}
