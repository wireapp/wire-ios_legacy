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

class BottomTabView: UIStackView {

    private let cellType: ConversationListButtonType
    let button = IconButton()
    let label = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Button.textBottomBarNormal)

    init(cellType: ConversationListButtonType) {
        self.cellType = cellType
        super.init(frame: .zero)
        self.configure(cellType: self.cellType)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showArchived(showArchived: Bool) {
        self.isHidden = !showArchived
        label.isHidden = !showArchived
        button.isHidden = !showArchived
    }

    private func configure(cellType: ConversationListButtonType) {
        setUpButton(cellType: cellType)
        setUpLabel(cellType: cellType)
        configureStackView()
    }

    private func setUpButton(cellType: ConversationListButtonType) {
        switch cellType {
        case .startUI:
            button.setIcon(.person, size: .tiny, for: .normal)
            button.tag = 1
        case .list:
            button.setIcon(.recentList, size: .tiny, for: [])
            button.tag = 2
        case .folder:
            button.setIcon(.folderList, size: .tiny, for: [])
            button.tag = 3
        case .archive:
            button.setIcon(.archive, size: .tiny, for: [])
            button.tag = 4
            button.isHidden = true
        }
        button.accessibilityIdentifier = cellType.accessibilityIdentifier
        button.accessibilityLabel = (cellType.accessibilityBase + ".label").localized
        button.accessibilityHint = (cellType.accessibilityBase + ".hint").localized

        button.setIconColor(SemanticColors.Button.textBottomBarNormal, for: .normal)
        button.setIconColor(SemanticColors.Button.textBottomBarSelected, for: .selected)
    }

    private func setUpLabel(cellType: ConversationListButtonType) {
            switch cellType {
            case .archive:
                label.text = L10n.Localizable.ConversationList.BottomBar.Archived.title
            case .startUI:
                label.text =  L10n.Localizable.ConversationList.BottomBar.Contacts.title
            case .list:
                label.text =  L10n.Localizable.ConversationList.BottomBar.Conversations.title
            case .folder:
                label.text =  L10n.Localizable.ConversationList.BottomBar.Folders.title
            }
    }

    private func configureStackView() {
        axis = .vertical
        distribution = .fillEqually
        alignment = .center
        isUserInteractionEnabled = true
        spacing = 4
        layer.cornerRadius = 6
        layer.masksToBounds = true
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        addArrangedSubview(button)
        addArrangedSubview(label)
    }
}
