//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

//final class ClientTabBarController: UITabBarController {
//
//    private var account: Account
//    private var selfUser: SelfUserType
//
//    init(account: Account, selfUser: SelfUserType) {
//        self.account = account
//        self.selfUser = selfUser
//
//        super.init(nibName: nil, bundle: nil)
//        setupViews()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupViews() {
//        let startTab = ConversationListViewController(account: account, selfUser: selfUser)
//        let listTab = ConversationListViewController(account: account, selfUser: selfUser)
//        let foldersTab = ConversationListViewController(account: account, selfUser: selfUser)
//        let archivedTab = ConversationListViewController(account: account, selfUser: selfUser)
//
////        listContentController.listViewModel.folderEnabled = true
//
//        startTab.tabBarItem = UITabBarItem(type: .startUI)
//        listTab.tabBarItem = UITabBarItem(type: .list)
//        foldersTab.tabBarItem = UITabBarItem(type: .folder)
//        archivedTab.tabBarItem = UITabBarItem(type: .archive)
//
//        setViewControllers([startTab, listTab, foldersTab, archivedTab], animated: true)
//    }
//
//    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//
//    }
//
//}

extension UITabBarItem {

    convenience init(type: TabBarItemType) {
        let image = UIImage.imageForIcon(type.icon,
                                         size: StyleKitIcon.Size.small.rawValue,
                                         color: SemanticColors.Button.textBottomBarNormal).withRenderingMode(.alwaysTemplate)
        self.init(title: type.title, image: image, selectedImage: nil)

        tag = type.tag

        /// Setup accessibility properties
        accessibilityIdentifier = type.accessibilityIdentifier
        accessibilityLabel = type.accessibilityLabel
        accessibilityHint = type.accessibilityHint
    }

}

enum TabBarItemType {

    typealias BottomBar = L10n.Localizable.ConversationList.BottomBar
    typealias TabBar = L10n.Accessibility.TabBar

    case startUI, list, folder, archive

    var tag: Int {
        switch self {
        case .startUI:
            return 1
        case .list:
            return 2
        case .folder:
            return 3
        case .archive:
            return 4
        }
    }

    var icon: StyleKitIcon {
        switch self {
        case .startUI:
            return .person
        case .list:
            return .conversation
        case .folder:
            return .folderList
        case .archive:
            return .archive
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

    var accessibilityHint: String {
        switch self {
        case .startUI:
            return TabBar.Contacts.hint
        case .list:
            return TabBar.Conversations.hint
        case .folder:
            return TabBar.Folders.hint
        case .archive:
            return TabBar.Archived.hint
        }
    }

}

enum ConversationListButtonType {
    typealias BottomBar = L10n.Localizable.ConversationList.BottomBar
    typealias TabBar = L10n.Accessibility.TabBar

    case archive, startUI, list, folder
    var accessibilityIdentifier: String {
        switch self {
        case .archive:
            return "bottomBarArchivedButton"
        case .startUI:
            return "bottomBarPlusButton"
        case .list:
            return "bottomBarRecentListButton"
        case .folder:
            return "bottomBarFolderListButton"
        }
    }
    var title: String {
        switch self {
        case .archive:
            return BottomBar.Archived.title
        case .startUI:
            return BottomBar.Contacts.title
        case .list:
            return BottomBar.Conversations.title
        case .folder:
            return BottomBar.Folders.title
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
    var accessibilityHint: String {
        switch self {
        case .startUI:
            return TabBar.Contacts.hint
        case .list:
            return TabBar.Conversations.hint
        case .folder:
            return TabBar.Folders.hint
        case .archive:
            return TabBar.Archived.hint
        }
    }
}

protocol ConversationListBottomBarControllerDelegate: AnyObject {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
    func didChangeTap(with type: ConversationListButtonType)
}

final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    private let mainStackview = UIStackView(axis: .horizontal)
    let startTabView = ConversationListTabView(tabType: .startUI)
    let listTabView = ConversationListTabView(tabType: .list)
    let folderTabView = ConversationListTabView(tabType: .folder)
    let archivedTabView = ConversationListTabView(tabType: .archive)

    private var userObserverToken: Any?
    private let heightConstant: CGFloat = 56
    private let xInset: CGFloat = 4
    private var allTabs: [ConversationListTabView] {
        return [startTabView, listTabView, folderTabView, archivedTabView]
    }

    private var selectedTab: ConversationListButtonType? {
        didSet {
            if let selectedTab = selectedTab {
                switch selectedTab {
                case .archive, .startUI:
                    return
                case .list:
                    highlightActiveTab(tabView: listTabView)
                case .folder:
                    highlightActiveTab(tabView: folderTabView)
                }
            }
        }
    }

    var showArchived: Bool = false {
        didSet {
            archivedTabView.isHidden = !showArchived
        }
    }

    required init() {
        super.init(nibName: nil, bundle: nil)

        setupStackViews()
        addTargetForStackViews()
        createConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: heightConstant),

            mainStackview.leftAnchor.constraint(equalTo: view.leftAnchor, constant: xInset),
            mainStackview.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -xInset),
            mainStackview.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            mainStackview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2)
        ])
    }

    private func addObservers() {
        guard let userSession = ZMUserSession.shared() else { return }

        userObserverToken = UserChangeInfo.add(observer: self, for: userSession.selfUser, in: userSession)
    }

    private func setupStackViews() {
        mainStackview.distribution = .fillEqually
        mainStackview.alignment = .fill
        mainStackview.translatesAutoresizingMaskIntoConstraints = false
        mainStackview.addArrangedSubview(startTabView)
        mainStackview.addArrangedSubview(listTabView)
        mainStackview.addArrangedSubview(folderTabView)
        mainStackview.addArrangedSubview(archivedTabView)

        view.addSubview(mainStackview)
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        view.addBorder(for: .top)
    }

    private func addTargetForStackViews() {
        var stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(listViewTapped))
        listTabView.addGestureRecognizer(stackViewTapGesture)
        listTabView.button.addTarget(self, action: #selector(listViewTapped), for: .touchUpInside)

        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(folderViewTapped))
        folderTabView.addGestureRecognizer(stackViewTapGesture)
        folderTabView.button.addTarget(self, action: #selector(folderViewTapped), for: .touchUpInside)

        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(archiveViewTapped))
        archivedTabView.addGestureRecognizer(stackViewTapGesture)
        archivedTabView.button.addTarget(self, action: #selector(archiveViewTapped), for: .touchUpInside)

        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(startUIViewTapped))
        startTabView.addGestureRecognizer(stackViewTapGesture)
        startTabView.button.addTarget(self, action: #selector(startUIViewTapped), for: .touchUpInside)

    }

    // MARK: - Target Action
    @objc
    private func listViewTapped() {
        updateSelectedTab(with: .list)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .list)
    }

    @objc
    private func folderViewTapped() {
        updateSelectedTab(with: .folder)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .folder)
    }

    @objc
    private func archiveViewTapped() {
        updateSelectedTab(with: .archive)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    @objc
    func startUIViewTapped() {
        updateSelectedTab(with: .startUI)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .startUI)
    }

    private func updateSelectedTab(with buttonType: ConversationListButtonType) {
        self.selectedTab = buttonType
    }

    private func highlightActiveTab(tabView selectedTabView: ConversationListTabView) {
        allTabs.forEach { subStackView in
            subStackView.backgroundColor = subStackView.isEqual(selectedTabView)
                                            ? .accent()
                                            : .clear
            subStackView.label.textColor = subStackView.label.isEqual(selectedTabView.label)
                                            ? SemanticColors.Button.textBottomBarSelected
                                            : SemanticColors.Button.textBottomBarNormal
            subStackView.button.isSelected = subStackView.isEqual(selectedTabView)
            subStackView.accessibilityValue = subStackView.isEqual(selectedTabView)
                                                ? L10n.Accessibility.TabBar.Item.value
                                                : nil
        }
    }

}

// MARK: - Helper

extension UIView {

    func fadeAndHide(_ hide: Bool, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = UIView.AnimationOptions()) {
        if !hide {
            alpha = 0
            isHidden = false
        }

        let animations = { self.alpha = hide ? 0 : 1 }
        let completion: (Bool) -> Void = { _ in self.isHidden = hide }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(), animations: animations, completion: completion)
    }

}

// MARK: - ConversationListViewModelRestorationDelegate
extension ConversationListBottomBarController: ConversationListViewModelRestorationDelegate {
    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool) {
        if enabled {
            selectedTab = .folder
        } else {
            selectedTab = .list
        }
    }
}

// don't need
extension ConversationListBottomBarController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.accentColorValueChanged else { return }

        switch selectedTab {
        case .list:
            listTabView.backgroundColor = .accent()
        case .folder:
            folderTabView.backgroundColor = .accent()
        default:
            return
        }
    }
}
