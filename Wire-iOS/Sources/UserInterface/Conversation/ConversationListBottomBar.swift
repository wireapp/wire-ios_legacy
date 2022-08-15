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
}

protocol ConversationListBottomBarControllerDelegate: AnyObject {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}

final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let buttonStackview = UIStackView(axis: .horizontal)

    let startUIButton  = IconButton()
    let listButton     = IconButton()
    let folderButton   = IconButton()
    let archivedButton = IconButton()

    let separator = UIView()

    private var userObserverToken: Any?
    private let heightConstant: CGFloat = 56
    private let xInset: CGFloat = 16

    var showArchived: Bool = false {
        didSet {
            self.archivedButton.isHidden = !self.showArchived
        }
    }

    var showSeparator: Bool {
        get {
            return !separator.isHidden
        }

        set {
            separator.fadeAndHide(!newValue)
        }
    }

    private var allButtons: [IconButton] {
        return [startUIButton, listButton, folderButton, archivedButton]
    }

    required init() {
        super.init(nibName: nil, bundle: nil)

        createViews()
        createConstraints()
        updateColorScheme()
        addObservers()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createViews() {
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        separator.backgroundColor = SemanticColors.View.backgroundConversationListTableViewCell
        separator.isHidden = true
        separator.translatesAutoresizingMaskIntoConstraints = false

        listButton.setIcon(.recentList, size: .tiny, for: [])
        listButton.addTarget(self, action: #selector(listButtonTapped), for: .touchUpInside)
        listButton.accessibilityIdentifier = "bottomBarRecentListButton"
        listButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.recent_button.label".localized
        listButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.recent_button.hint".localized

        folderButton.setIcon(.folderList, size: .tiny, for: [])
        folderButton.addTarget(self, action: #selector(folderButtonTapped), for: .touchUpInside)
        folderButton.accessibilityIdentifier = "bottomBarFolderListButton"
        folderButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.folder_button.label".localized
        folderButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.folder_button.hint".localized

        archivedButton.setIcon(.archive, size: .tiny, for: [])
        archivedButton.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"
        archivedButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.archived_button.label".localized
        archivedButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.archived_button.hint".localized
        archivedButton.isHidden = true

        startUIButton.setIcon(.person, size: .tiny, for: .normal)
        startUIButton.addTarget(self, action: #selector(startUIButtonTapped), for: .touchUpInside)
        startUIButton.accessibilityIdentifier = "bottomBarPlusButton"
        startUIButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.contacts_button.label".localized
        startUIButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.contacts_button.hint".localized

        buttonStackview.distribution = .equalSpacing
        buttonStackview.alignment = .center
        buttonStackview.translatesAutoresizingMaskIntoConstraints = false

        allButtons.forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            buttonStackview.addArrangedSubview(button)
        }

        view.addSubview(buttonStackview)
        view.addSubview(separator)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: heightConstant),

            separator.heightAnchor.constraint(equalToConstant: .hairline),
            separator.leftAnchor.constraint(equalTo: view.leftAnchor),
            separator.rightAnchor.constraint(equalTo: view.rightAnchor),
            separator.topAnchor.constraint(equalTo: view.topAnchor),

            buttonStackview.leftAnchor.constraint(equalTo: view.leftAnchor, constant: xInset),
            buttonStackview.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -xInset),
            buttonStackview.topAnchor.constraint(equalTo: view.topAnchor),
            buttonStackview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addObservers() {
        guard let userSession = ZMUserSession.shared() else { return }

        userObserverToken = UserChangeInfo.add(observer: self, for: userSession.selfUser, in: userSession)
    }

    fileprivate func updateColorScheme() {
        allButtons.forEach { button in
            button.setIconColor(SemanticColors.Label.textConversationListCell, for: .normal)
            button.setIconColor(.accent(), for: .selected)
        }
    }

    // MARK: - Target Action

    @objc
    private func listButtonTapped(_ sender: IconButton) {
        updateSelection(with: sender)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .list)
    }

    @objc
    private func folderButtonTapped(_ sender: IconButton) {
        updateSelection(with: sender)
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .folder)
    }

    @objc
    private func archivedButtonTapped(_ sender: IconButton) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .archive)
    }

    @objc
    func startUIButtonTapped(_ sender: Any?) {
        delegate?.conversationListBottomBar(self, didTapButtonWithType: .startUI)
    }

    private func updateSelection(with button: IconButton) {
        allButtons.forEach({ $0.isSelected = $0 == button })
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
            updateSelection(with: folderButton)
        } else {
            updateSelection(with: listButton)
        }
    }
}

extension ConversationListBottomBarController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.accentColorValueChanged else { return }

        updateColorScheme()
    }

}
