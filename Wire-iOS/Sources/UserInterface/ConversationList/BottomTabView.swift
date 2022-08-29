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

class ConversationListTabView: UIStackView {

    let tabType: ConversationListButtonType
    let button = IconButton()
    let label = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Button.textBottomBarNormal)

    // MARK: - Initialization

    init(tabType: ConversationListButtonType) {
        self.tabType = tabType
        super.init(frame: .zero)
        self.configure(tabType: self.tabType)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(tabType: ConversationListButtonType) {
        setUpButton(tabType: tabType)
        setUpLabel(tabType: tabType)
        configureStackView()
    }

    private func setUpButton(tabType: ConversationListButtonType) {
        switch tabType {
        case .startUI:
            button.setIcon(.person, size: .tiny, for: .normal)
        case .list:
            button.setIcon(.recentList, size: .tiny, for: [])
        case .folder:
            button.setIcon(.folderList, size: .tiny, for: [])
        case .archive:
            button.setIcon(.archive, size: .tiny, for: [])
            button.isHidden = true
        }
        button.accessibilityIdentifier = tabType.accessibilityIdentifier
        button.accessibilityLabel = tabType.voiceOverLabel
        button.accessibilityHint = tabType.voiceOverHint

        button.setIconColor(SemanticColors.Button.textBottomBarNormal, for: .normal)
        button.setIconColor(SemanticColors.Button.textBottomBarSelected, for: .selected)
    }

    private func setUpLabel(tabType: ConversationListButtonType) {
            switch tabType {
            case .archive:
                label.text = L10n.Localizable.ConversationList.BottomBar.Archived.title
            case .startUI:
                label.text = L10n.Localizable.ConversationList.BottomBar.Contacts.title
            case .list:
                label.text = L10n.Localizable.ConversationList.BottomBar.Conversations.title
            case .folder:
                label.text = L10n.Localizable.ConversationList.BottomBar.Folders.title
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

    // MARK: - Adaptive UI

    func showArchivedTab(when archivedIsVisible: Bool) {
        self.isHidden = !archivedIsVisible
        label.isHidden = !archivedIsVisible
        button.isHidden = !archivedIsVisible
    }
}
