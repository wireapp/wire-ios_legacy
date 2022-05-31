//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireDataModel
import WireCommonComponents

protocol FolderPickerViewControllerDelegate {
    func didPickFolder(_ folder: LabelType, for conversation: ZMConversation)
}

final class FolderPickerViewController: UIViewController {

    var delegate: FolderPickerViewControllerDelegate?

    fileprivate var conversationDirectory: ConversationDirectoryType
    fileprivate var items: [LabelType] = []
    fileprivate let colorSchemeVariant = ColorScheme.default.variant
    fileprivate let conversation: ZMConversation
    private let hintLabel = DynamicFontLabel(fontSpec: .mediumSemiboldFont, color: .textForeground)
    private let collectionViewLayout = UICollectionViewFlowLayout()

    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
    }()

    init(conversation: ZMConversation, directory: ConversationDirectoryType) {
        self.conversation = conversation
        self.conversationDirectory = directory

        super.init(nibName: nil, bundle: nil)

        loadFolders()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavbar()
        configureSubviews()
        configureConstraints()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorScheme.default.statusBarStyle
    }

    private func configureNavbar() {
        title = "folder.picker.title".localized(uppercased: true)

        let newFolderItem = UIBarButtonItem(icon: .plus, target: self, action: #selector(createNewFolder))
        newFolderItem.accessibilityIdentifier = "button.newfolder.create"

        navigationItem.leftBarButtonItem = navigationController?.closeItem()
        navigationItem.rightBarButtonItem = newFolderItem
    }

    private func loadFolders() {
        items = conversationDirectory.allFolders
        hintLabel.isHidden = !items.isEmpty
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func configureSubviews() {

        hintLabel.text = "folder.picker.empty.hint".localized
        hintLabel.numberOfLines = 0
        hintLabel.textColor = UIColor.from(scheme: .textForeground)
        hintLabel.textAlignment = .center

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.from(scheme: .contentBackground)
        collectionView.alwaysBounceVertical = true

        collectionViewLayout.minimumLineSpacing = 0

        CheckmarkCell.register(in: collectionView)

    }

    private func configureConstraints() {

        view.addSubview(collectionView)
        view.addSubview(hintLabel)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitInSuperview()

        NSLayoutConstraint.activate([hintLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
                                     hintLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
                                     hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
    }

    @objc private func createNewFolder() {
        let folderCreation = FolderCreationController(conversation: conversation, directory: conversationDirectory)
        folderCreation.delegate = self
        self.navigationController?.pushViewController(folderCreation, animated: true)
    }

}

// MARK: - Table View

extension FolderPickerViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)
        let item = items[indexPath.row]
        cell.title = item.name
        cell.showSeparator = indexPath.row < (items.count - 1)
        if let folder = conversation.folder {
            cell.showCheckmark = (folder.remoteIdentifier == item.remoteIdentifier)
        } else {
            cell.showCheckmark = false
        }

        return cell
    }

    private func pickFolder(_ folder: LabelType) {
        self.delegate?.didPickFolder(folder, for: conversation)
        self.dismissIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedItem = items[indexPath.row]
        pickFolder(selectedItem)
    }

    // MARK: Layout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

}

extension FolderPickerViewController: FolderCreationControllerDelegate {

    func folderController(_ controller: FolderCreationController, didCreateFolder folder: LabelType) {
        pickFolder(folder)
    }

}
