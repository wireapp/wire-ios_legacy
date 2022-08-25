//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class BottomBarCell: UIStackView {

    let cellStackView = UIStackView(axis: .vertical)
    let cellButton = IconButton()
    let cellLabel = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Button.textBottomBarNormal)

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(cellType: ConversationListButtonType) {
        setUpButton(cellType: cellType)
        setUpLabel(cellType: cellType)
        configureStackView()
    }

    func showArchived(showArchived: Bool) {
        self.isHidden = !showArchived
        cellLabel.isHidden = !showArchived
        cellButton.isHidden = !showArchived
    }

    private func setUpButton(cellType: ConversationListButtonType) {
        switch cellType {
        case .archive:
            cellButton.setIcon(.archive, size: .tiny, for: [])
            cellButton.tag = 4
            cellButton.accessibilityIdentifier = "bottomBarArchivedButton"
            cellButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.archived_button.label".localized
            cellButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.archived_button.hint".localized
            cellButton.isHidden = true
        case .startUI:
            cellButton.setIcon(.person, size: .tiny, for: .normal)
            cellButton.tag = 1
            cellButton.accessibilityIdentifier = "bottomBarPlusButton"
            cellButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.contacts_button.label".localized
            cellButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.contacts_button.hint".localized
        case .list:
            cellButton.setIcon(.recentList, size: .tiny, for: [])
            cellButton.tag = 2
            cellButton.accessibilityIdentifier = "bottomBarRecentListButton"
            cellButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.recent_button.label".localized
            cellButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.recent_button.hint".localized
        case .folder:
            cellButton.setIcon(.folderList, size: .tiny, for: [])
            cellButton.tag = 3
            cellButton.accessibilityIdentifier = "bottomBarFolderListButton"
            cellButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.folder_button.label".localized
            cellButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.folder_button.hint".localized
        }
        cellButton.setIconColor(SemanticColors.Button.textBottomBarNormal, for: .normal)
        cellButton.setIconColor(SemanticColors.Button.textBottomBarSelected, for: .selected)
    }

    private func setUpLabel(cellType: ConversationListButtonType) {
            switch cellType {
            case .archive:
                cellLabel.text = L10n.Localizable.ConversationList.BottomBar.Archived.title
            case .startUI:
                cellLabel.text =  L10n.Localizable.ConversationList.BottomBar.Contacts.title
            case .list:
                cellLabel.text =  L10n.Localizable.ConversationList.BottomBar.Conversations.title
            case .folder:
                cellLabel.text =  L10n.Localizable.ConversationList.BottomBar.Folders.title
            }
    }

    private func configureStackView() {
        distribution = .fillEqually
        alignment = .center
        isUserInteractionEnabled = true
        spacing = 4
        layer.cornerRadius = 6
        layer.masksToBounds = true
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        addArrangedSubview(cellButton)
        addArrangedSubview(cellLabel)
    }
}
