//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents

protocol ConversationListTabBarControllerDelegate: AnyObject {
    func didChangeTab(with type: TabBarItemType)
}

enum TabBarItemType: Int, CaseIterable {

    typealias BottomBar = L10n.Localizable.ConversationList.BottomBar
    typealias TabBar = L10n.Accessibility.TabBar

    case startUI, list, folder, archive

    var order: Int {
        return rawValue
    }

    var icon: UIImage {
        switch self {
        case .startUI:
            return Asset.Images.contactsOutline.image
        case .list:
            return Asset.Images.conversationsOutline.image
        case .folder:
            return Asset.Images.foldersOutline.image
        case .archive:
            return Asset.Images.archiveOutline.image
        }
    }

    var selectedIcon: UIImage {
        switch self {
        case .startUI:
            return Asset.Images.contactsFilled.image
        case .list:
            return Asset.Images.conversationsFilled.image
        case .folder:
            return Asset.Images.foldersFilled.image
        case .archive:
            return Asset.Images.archiveFilled.image
        }
    }

    var title: String {
        switch self {
        case .startUI:
            return BottomBar.Contacts.title
        case .list:
            return BottomBar.Conversations.title
        case .folder:
            return BottomBar.Folders.title
        case .archive:
            return BottomBar.Archived.title
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .startUI:
            return "bottomBarPlusButton"
        case .list:
            return "bottomBarRecentListButton"
        case .folder:
            return "bottomBarFolderListButton"
        case .archive:
            return "bottomBarArchivedButton"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .startUI:
            return TabBar.Contacts.description
        case .list:
            return TabBar.Conversations.description
        case .folder:
            return TabBar.Folders.description
        case .archive:
            return TabBar.Archived.description
        }
    }

    var accessibilityHint: String? {
        switch self {
        case .startUI:
            return TabBar.Contacts.hint
        case .archive:
            return TabBar.Archived.hint
        case .list, .folder:
            return nil
        }
    }

}

final class ConversationListTabBar: UITabBar {

    private let startTab = UITabBarItem(type: .startUI)
    private let listTab = UITabBarItem(type: .list)
    private let folderTab = UITabBarItem(type: .folder)
    private let archivedTab = UITabBarItem(type: .archive)

    var showArchived: Bool = false {
        didSet {
            var tabs: [UITabBarItem] = [startTab, listTab, folderTab]
            if showArchived {
                tabs.append(archivedTab)
            }
            setItems(tabs, animated: true)
        }
    }

    var selectedTab: TabBarItemType? {
        didSet {
            if let selectedTab = selectedTab {
                switch selectedTab {
                case .archive, .startUI:
                    return
                case .list:
                    selectedItem = listTab
                case .folder:
                    selectedItem = folderTab
                }
            }
        }
    }

    // MARK: - Init
    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        setupLargeContentViewer()

        barTintColor = SemanticColors.View.backgroundConversationList
        isTranslucent = false
        items = [startTab, listTab, folderTab, archivedTab]
    }

    private func setupLargeContentViewer() {
        let interaction = UILargeContentViewerInteraction(delegate: self)
        addInteraction(interaction)

        showsLargeContentViewer = true
        scalesLargeContentImage = true
    }

}

// MARK: - ConversationListViewModelRestorationDelegate

extension ConversationListTabBar: ConversationListViewModelRestorationDelegate {

    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool) {
        if enabled {
            selectedTab = .folder
        } else {
            selectedTab = .list
        }
    }

}

// MARK: - UILargeContentViewerInteractionDelegate

extension ConversationListTabBar: UILargeContentViewerInteractionDelegate {

    func largeContentViewerInteraction(_: UILargeContentViewerInteraction, itemAt: CGPoint) -> UILargeContentViewerItem? {
        setupLargeContentViewer(at: itemAt)

        return self
    }

    private func setupLargeContentViewer(at location: CGPoint) {
        guard let tabBarItem = tabBarItem(at: location) else {
            return
        }
        largeContentTitle = tabBarItem.title
        largeContentImage = tabBarItem.image
    }

}

extension UITabBarItem {

    convenience init(type: TabBarItemType) {
        self.init(title: type.title,
                  image: type.icon.resize(for: .medium).withRenderingMode(.alwaysTemplate),
                  selectedImage: type.selectedIcon.resize(for: .medium).withRenderingMode(.alwaysTemplate))

        tag = type.order

        /// Setup accessibility properties
        accessibilityIdentifier = type.accessibilityIdentifier
        accessibilityLabel = type.accessibilityLabel
        accessibilityHint = type.accessibilityHint
    }

}

private extension UITabBar {

    func tabBarItem(at location: CGPoint) -> UITabBarItem? {
        guard let itemsCount = items?.count else {
            return nil
        }

        let itemWidth: CGFloat = (self.frame.width / CGFloat(itemsCount))

        switch location.x {
        case 0 ..< itemWidth:
            return UITabBarItem(type: .startUI)
        case itemWidth ..< (2 * itemWidth):
            return UITabBarItem(type: .list)
        case (2 * itemWidth) ..< (3 * itemWidth):
            return UITabBarItem(type: .folder)
        default:
            return UITabBarItem(type: .archive)
        }
    }

}
