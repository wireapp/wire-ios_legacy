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

enum ConversationListButtonType {
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
    var voiceOverLabel: String {
        switch self {
        case .archive:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.ArchivedButton.label
        case .startUI:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.ContactsButton.label
        case .list:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.RecentButton.label
        case .folder:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.FolderButton.label
        }
    }
    var voiceOverHint: String {
        switch self {
        case .archive:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.ArchivedButton.hint
        case .startUI:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.ContactsButton.hint
        case .list:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.RecentButton.hint
        case .folder:
            return L10n.Localizable.ConversationList.Voiceover.BottomBar.FolderButton.hint
        }
    }
}

protocol ConversationListBottomBarControllerDelegate: AnyObject {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}

final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let mainStackview = UIStackView(axis: .horizontal)
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

    private var currentlySelectedTab: ConversationListButtonType? {
        didSet {
            if let currentlySelectedTab = currentlySelectedTab {
                switch currentlySelectedTab {
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

    var archivedIsVisible: Bool = false {
        didSet {
            archivedTabView.showArchivedTab(when: archivedIsVisible)
        }
    }

    required init() {
        super.init(nibName: nil, bundle: nil)

        setupStackViews()
        addTargetForStackViews()
        createConstraints()
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
        updateCurrentlySelectedTab(with: .list)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .list)
    }

    @objc
    private func folderViewTapped() {
        updateCurrentlySelectedTab(with: .folder)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .folder)
    }

    @objc
    private func archiveViewTapped() {
        updateCurrentlySelectedTab(with: .archive)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    @objc
    func startUIViewTapped() {
        updateCurrentlySelectedTab(with: .startUI)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .startUI)
    }

    private func updateCurrentlySelectedTab(with buttonType: ConversationListButtonType) {
        self.currentlySelectedTab = buttonType
    }

    private func highlightActiveTab(tabView selectedTabView: ConversationListTabView) {
        allTabs.forEach { subStackView in
            subStackView.backgroundColor = subStackView.isEqual(selectedTabView) ? .accent() : .clear
            subStackView.label.textColor = subStackView.label.isEqual(selectedTabView.label) ? SemanticColors.Button.textBottomBarSelected : SemanticColors.Button.textBottomBarNormal
            subStackView.button.isSelected = subStackView.isEqual(selectedTabView)
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
            currentlySelectedTab = .folder
        } else {
            currentlySelectedTab = .list
        }
    }
}

extension ConversationListBottomBarController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.accentColorValueChanged else { return }

        switch currentlySelectedTab {
        case .list:
            listTabView.backgroundColor = .accent()
        case .folder:
            folderTabView.backgroundColor = .accent()
        case .archive:
            archivedTabView.backgroundColor = .accent()
        default:
            return
        }
    }
}
