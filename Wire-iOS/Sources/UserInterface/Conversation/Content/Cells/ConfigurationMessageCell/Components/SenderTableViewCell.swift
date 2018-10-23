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

class SenderTableViewCell: UITableViewCell {

    private let component = SenderCellComponent()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
        configureConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {
        contentView.addSubview(component)
    }

    private func configureConstraints() {
        component.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            component.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            component.topAnchor.constraint(equalTo: contentView.topAnchor),
            component.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            component.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Cell

    override func prepareForReuse() {
        super.prepareForReuse()
        component.prepareForReuse()
    }

    func configure(with message: ZMConversationMessage) {
        guard let sender = message.sender else {
            return
        }

        component.configure(with: sender)
    }

}
