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


import Classy
import Cartography


public class ParticipantsCell: IconSystemCell {

    private let collectionViewController = ParticipantsCollectionViewController<ParticipantsUserCell>()

    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCollectionView()
        createConstraints()
        CASStyler.default().styleItem(self)
    }

    private func setupCollectionView() {
        // Cells should not be selectable (for now)
        collectionViewController.collectionView.isUserInteractionEnabled = false
        messageContentView.addSubview(collectionViewController.view)

        collectionViewController.configureCell = { [weak self] (user, cell) in
            cell.user = user
            cell.dimmed = self?.message.systemMessageData?.systemMessageType == .participantsRemoved
        }

        collectionViewController.selectAction = { [weak self] (user, cell) in
            guard let `self` = self else { return }
            self.delegate.conversationCell?(self, userTapped: user, in: cell)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        constrain(messageContentView, labelView, collectionViewController.view) { container, label, participants in
            participants.leading == label.leading
            participants.trailing == container.trailing - 72
            participants.top == label.bottom + 8
            participants.bottom == container.bottom - 8
        }
    }

    override public func configure(for message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configure(for: message, layoutProperties: layoutProperties)
        let model = ParticipantsCellViewModel(font: labelFont, boldFont: labelBoldFont, textColor: labelTextColor, message: message)
        leftIconView.image = model.image()
        labelView.attributedText = model.attributedTitle()
        labelView.accessibilityLabel = labelView.attributedText?.string

        // We need a layout pass here in order for the collectionView to pick up the correct size
        setNeedsLayout()
        layoutIfNeeded()
        collectionViewController.users = model.sortedUsers()
    }

}
