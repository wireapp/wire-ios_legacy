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

    let button = IconButton()
    let label = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Button.textBottomBarNormal)

    // MARK: - Initialization

    init(tabType: ConversationListButtonType) {
        super.init(frame: .zero)
        self.configure(tabType)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func configure(_ tabType: ConversationListButtonType) {
        setupButton(tabType)
        setupLabel(tabType)
        setupAccessibility(tabType)
        setupViews()
    }

    private func setupButton(_ tabType: ConversationListButtonType) {
        switch tabType {
        case .startUI:
            button.setIcon(.person, size: .tiny, for: .normal)
        case .list:
            button.setIcon(.recentList, size: .tiny, for: [])
        case .folder:
            button.setIcon(.folderList, size: .tiny, for: [])
        case .archive:
            button.setIcon(.archive, size: .tiny, for: [])
        }

        button.setIconColor(SemanticColors.Button.textBottomBarNormal, for: .normal)
        button.setIconColor(SemanticColors.Button.textBottomBarSelected, for: .selected)
    }

    private func setupLabel(_ tabType: ConversationListButtonType) {
        label.text = tabType.title
    }

    private func setupViews() {
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

    private func setupAccessibility(_ tabType: ConversationListButtonType) {
        isAccessibilityElement = true
        accessibilityIdentifier = tabType.accessibilityIdentifier
        accessibilityTraits = .button
        accessibilityLabel = tabType.accessibilityLabel
        accessibilityHint = tabType.accessibilityHint
    }

}
