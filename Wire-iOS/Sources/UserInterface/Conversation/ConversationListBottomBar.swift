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
    var accessibilityBase: String {
        switch self {
        case .archive:
            return "conversation_list.voiceover.bottom_bar.archived_button".localized
        case .startUI:
            return "conversation_list.voiceover.bottom_bar.contacts_button"
        case .list:
            return "conversation_list.voiceover.bottom_bar.recent_button"
        case .folder:
            return "conversation_list.voiceover.bottom_bar.folder_button"
        }
    }
}

protocol ConversationListBottomBarControllerDelegate: AnyObject {
    func conversationListBottomBar(_ bar: ConversationListBottomBarController, didTapButtonWithType buttonType: ConversationListButtonType)
}

final class ConversationListBottomBarController: UIViewController {

    weak var delegate: ConversationListBottomBarControllerDelegate?

    let mainStackview = UIStackView(axis: .horizontal)
    let startBarCell = BottomTabView(cellType: .startUI)
    let listBarCell = BottomTabView(cellType: .list)
    let folderBarCell = BottomTabView(cellType: .folder)
    let archivedBarCell = BottomTabView(cellType: .archive)

    private var userObserverToken: Any?
    private let heightConstant: CGFloat = 56
    private let xInset: CGFloat = 4
    private var currentlySelected: ConversationListButtonType?

    var showArchived: Bool = false {
        didSet {
            archivedBarCell.showArchived(showArchived: self.showArchived)
        }
    }

    private var allSubStackViews: [BottomTabView] {
        return [startBarCell, listBarCell, folderBarCell, archivedBarCell]
    }

    required init() {
        super.init(nibName: nil, bundle: nil)

        createViews()
        createConstraints()
        addObservers()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createViews() {
        setupStackViews()
        addTargetForStackViews()

        view.addSubview(mainStackview)
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        view.addBorder(for: .top)
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
        startBarCell.button.addTarget(self, action: #selector(startUIButtonTapped), for: .touchUpInside)
        listBarCell.button.addTarget(self, action: #selector(listButtonTapped), for: .touchUpInside)
        folderBarCell.button.addTarget(self, action: #selector(folderButtonTapped), for: .touchUpInside)
        archivedBarCell.button.addTarget(self, action: #selector(archivedButtonTapped), for: .touchUpInside)

        mainStackview.distribution = .fillEqually
        mainStackview.alignment = .fill
        mainStackview.translatesAutoresizingMaskIntoConstraints = false
        mainStackview.addArrangedSubview(startBarCell)
        mainStackview.addArrangedSubview(listBarCell)
        mainStackview.addArrangedSubview(folderBarCell)
        mainStackview.addArrangedSubview(archivedBarCell)
    }

    private func addTargetForStackViews() {
        var stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(listStackViewTapped))
        listBarCell.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(folderStackViewTapped))
        folderBarCell.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(archiveStackViewTapped))
        archivedBarCell.addGestureRecognizer(stackViewTapGesture)
        stackViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(startUIStackViewTapped))
        startBarCell.addGestureRecognizer(stackViewTapGesture)
    }

    // MARK: - Target Action
    @objc
    private func listStackViewTapped() {
        listBarCell.button.sendActions(for: .touchUpInside)
    }

    @objc
    private func folderStackViewTapped() {
        folderBarCell.button.sendActions(for: .touchUpInside)
    }

    @objc
    private func archiveStackViewTapped() {
        archivedBarCell.button.sendActions(for: .touchUpInside)
    }

    @objc
    private func startUIStackViewTapped() {
        startBarCell.button.sendActions(for: .touchUpInside)
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
        allSubStackViews.forEach { subStackView in
            subStackView.button.isSelected = subStackView.button.isEqual(button)
            updateColorForSpecifiedStackView(button: subStackView.button)
        }
    }

    private func updateColorForSpecifiedStackView(button: IconButton) {
        guard button.isSelected else {
            return
        }

        switch button.tag {
        case 1:
            setSelectedType(type: .startUI)
        case 2:
            setSelectedType(type: .list)
            setActiveTab(stackView: listBarCell)
        case 3:
            setSelectedType(type: .folder)
            setActiveTab(stackView: folderBarCell)
        case 4:
            setSelectedType(type: .archive)
            setActiveTab(stackView: archivedBarCell)
        default:
            return
        }
    }

    private func setActiveTab(stackView: BottomTabView) {
        allSubStackViews.forEach { subStackView in
            subStackView.backgroundColor = subStackView.isEqual(stackView) ? .accent() : .clear
            subStackView.label.textColor = subStackView.label.isEqual(stackView.label) ? SemanticColors.Button.textBottomBarSelected : SemanticColors.Button.textBottomBarNormal
        }
    }

    fileprivate func setSelectedType(type: ConversationListButtonType) {
        self.currentlySelected = type
    }

    fileprivate func updateBottomBarAfterColorChange() {
        switch currentlySelected {
        case .list:
            listBarCell.backgroundColor = .accent()
        case .folder:
            folderBarCell.backgroundColor = .accent()
        case .archive:
            archivedBarCell.backgroundColor = .accent()
        default:
            return
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
            updateSelection(with: folderBarCell.button)
            currentlySelected = .folder
        } else {
            updateSelection(with: listBarCell.button)
            currentlySelected = .list
        }
    }
}

extension ConversationListBottomBarController: ZMUserObserver {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.accentColorValueChanged else { return }

        updateBottomBarAfterColorChange()
    }
}
