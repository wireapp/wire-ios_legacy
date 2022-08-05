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

    let mainStackview = UIStackView(axis: .horizontal)
    let startUIStackView  = UIStackView(axis: .vertical)
    let listStackView   = UIStackView(axis: .vertical)
    let folderStackView = UIStackView(axis: .vertical)
    let archivedStackView = UIStackView(axis: .vertical)

    let startUIButton = IconButton()
    let listButton = IconButton()
    let folderButton = IconButton()
    let archivedButton = IconButton()

    let startUILabel = DynamicFontLabel(
        text: "Contacts",
        fontSpec: .mediumRegularFont,
        color: SemanticColors.ButtonsColor.bottomBarNormalButton)
    let listLabel = DynamicFontLabel(
        text: "Conversations",
        fontSpec: .mediumRegularFont,
        color: SemanticColors.ButtonsColor.bottomBarNormalButton)
    let folderLabel = DynamicFontLabel(
        text: "Folders",
        fontSpec: .mediumRegularFont,
        color: SemanticColors.ButtonsColor.bottomBarNormalButton)
    let archivedLabel = DynamicFontLabel(
        text: "Archived",
        fontSpec: .mediumRegularFont,
        color: SemanticColors.ButtonsColor.bottomBarNormalButton)

    private var userObserverToken: Any?
    private let heightConstant: CGFloat = 56
    private let xInset: CGFloat = 16

    var showArchived: Bool = false {
        didSet {
            self.archivedButton.isHidden = !self.showArchived
            self.archivedStackView.isHidden = !self.showArchived
            self.archivedLabel.isHidden = !self.showArchived
        }
    }

    private var allButtons: [IconButton] {
        return [startUIButton, listButton, folderButton, archivedButton]
    }

    private var allSubStackViews: [UIStackView] {
        return [startUIStackView, listStackView, folderStackView, archivedStackView]
    }

    private var allLabels: [UILabel] {
        return [startUILabel, listLabel, folderLabel, archivedLabel]
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
        startUIButton.setIcon(.person, size: .tiny, for: .normal)
        startUIButton.addTarget(self, action: #selector(startUIButtonTapped), for: .touchUpInside)
        startUIButton.tag = 1
        startUIButton.accessibilityIdentifier = "bottomBarPlusButton"
        startUIButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.contacts_button.label".localized
        startUIButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.contacts_button.hint".localized

        listButton.setIcon(.recentList, size: .tiny, for: [])
        listButton.addTarget(self, action: #selector(listButtonTapped), for: .touchUpInside)
        listButton.tag = 2
        listButton.accessibilityIdentifier = "bottomBarRecentListButton"
        listButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.recent_button.label".localized
        listButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.recent_button.hint".localized

        folderButton.setIcon(.folderList, size: .tiny, for: [])
        folderButton.addTarget(self, action: #selector(folderButtonTapped), for: .touchUpInside)
        folderButton.tag = 3
        folderButton.accessibilityIdentifier = "bottomBarFolderListButton"
        folderButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.folder_button.label".localized
        folderButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.folder_button.hint".localized

        archivedButton.setIcon(.archive, size: .tiny, for: [])
        archivedButton.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)
        archivedButton.tag = 4
        archivedButton.accessibilityIdentifier = "bottomBarArchivedButton"
        archivedButton.accessibilityLabel = "conversation_list.voiceover.bottom_bar.archived_button.label".localized
        archivedButton.accessibilityHint = "conversation_list.voiceover.bottom_bar.archived_button.hint".localized
        archivedButton.isHidden = true

        setupStackViews()
        populeteSubStackViews()
        addTargetForStackViews()

        view.addSubview(mainStackview)
        view.backgroundColor = SemanticColors.Background.conversationList
        view.addTopBorder(color: SemanticColors.Background.conversationListTableCellBorder)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: heightConstant),

            mainStackview.leftAnchor.constraint(equalTo: view.leftAnchor, constant: xInset),
            mainStackview.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -xInset),
            mainStackview.topAnchor.constraint(equalTo: view.topAnchor, constant: 1),
            mainStackview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2)
        ])
    }

    private func addObservers() {
        guard let userSession = ZMUserSession.shared() else { return }

        userObserverToken = UserChangeInfo.add(observer: self, for: userSession.selfUser, in: userSession)
    }

    fileprivate func updateColorScheme() {
        allButtons.forEach { button in
            button.setIconColor(SemanticColors.ButtonsColor.bottomBarNormalButton, for: .normal)
            button.setIconColor(SemanticColors.ButtonsColor.bottomBarSelectedButton, for: .selected)
        }
    }

    private func setupStackViews() {
        allSubStackViews.forEach { stackView in
            stackView.distribution = .fillEqually
            stackView.alignment = .center
            stackView.isUserInteractionEnabled = true
            stackView.spacing = 4
            stackView.layer.cornerRadius = 6
            stackView.layer.masksToBounds = true
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

            mainStackview.distribution = .fillEqually
            mainStackview.alignment = .fill
            mainStackview.translatesAutoresizingMaskIntoConstraints = false
            mainStackview.addArrangedSubview(startUIStackView)
            mainStackview.addArrangedSubview(listStackView)
            mainStackview.addArrangedSubview(folderStackView)
            mainStackview.addArrangedSubview(archivedStackView)
        }
    }

    private func populeteSubStackViews() {
        startUIStackView.addArrangedSubview(startUIButton)
        startUIStackView.addArrangedSubview(startUILabel)
        listStackView.addArrangedSubview(listButton)
        listStackView.addArrangedSubview(listLabel)
        folderStackView.addArrangedSubview(folderButton)
        folderStackView.addArrangedSubview(folderLabel)
        archivedStackView.addArrangedSubview(archivedButton)
        archivedStackView.addArrangedSubview(archivedLabel)
    }

    private func addTargetForStackViews() {
        var stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(listStackViewTapped))
        listStackView.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(folderStackViewTapped))
        folderStackView.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(archiveStackViewTapped))
        archivedStackView.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(startUIStackViewTapped))
        startUIStackView.addGestureRecognizer(stackViewTapGesture)
    }

    // MARK: - Target Action
    @objc
    private func listStackViewTapped() {
        listButton.sendActions(for: .touchUpInside)
    }

    @objc
    private func folderStackViewTapped() {
        folderButton.sendActions(for: .touchUpInside)
    }

    @objc
    private func archiveStackViewTapped() {
        archivedButton.sendActions(for: .touchUpInside)
    }

    @objc
    private func startUIStackViewTapped() {
        startUIButton.sendActions(for: .touchUpInside)
    }

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
        allButtons.forEach { currentButton in
            currentButton.isSelected = currentButton.isEqual(button)
            updateColorForSpecifiedStackView(button: currentButton)
        }
    }

    private func updateColorForSpecifiedStackView(button: IconButton) {
        guard button.isSelected else {
            return
        }

        switch button.tag {
        case 2:
            setActiveTab(stackView: listStackView, label: listLabel)
        case 3:
            setActiveTab(stackView: folderStackView, label: folderLabel)
        case 4:
            setActiveTab(stackView: archivedStackView, label: archivedLabel)
        default:
            return
        }
    }

    private func setActiveTab(stackView: UIStackView, label: UILabel) {
        allLabels.forEach { currentLabel in
            currentLabel.textColor = currentLabel.isEqual(label) ? SemanticColors.ButtonsColor.bottomBarSelectedButton : SemanticColors.ButtonsColor.bottomBarNormalButton
        }
        allSubStackViews.forEach { currentStackView in
            currentStackView.backgroundColor = currentStackView.isEqual(stackView) ? .accent() : .clear
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
