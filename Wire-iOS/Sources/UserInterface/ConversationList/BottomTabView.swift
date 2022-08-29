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

final class ConversationListTabView: UIStackView {

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
        setupButton(tabType: tabType)
        setupLabel(tabType: tabType)
        configureStackView()
    }

    private func setupButton(tabType: ConversationListButtonType) {
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
        button.accessibilityLabel = tabType.accessibilityLabel
        button.accessibilityHint = tabType.accessibilityHint

        button.setIconColor(SemanticColors.Button.textBottomBarNormal, for: .normal)
        button.setIconColor(SemanticColors.Button.textBottomBarSelected, for: .selected)
    }

    private func setupLabel(tabType: ConversationListButtonType) {
        typealias bottomBarLocalizable = L10n.Localizable.ConversationList.BottomBar
            switch tabType {
            case .archive:
                label.text = bottomBarLocalizable.Archived.title
            case .startUI:
                label.text = bottomBarLocalizable.Contacts.title
            case .list:
                label.text = bottomBarLocalizable.Conversations.title
            case .folder:
                label.text = bottomBarLocalizable.Folders.title
            }
    }

    private func configureStackView() {
        axis = .vertical
        distribution = .fillEqually
        alignment = .center
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
