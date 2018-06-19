//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationTimeoutOptionsViewController: UIViewController {

    fileprivate let conversation: ZMConversation
    fileprivate let items: [ZMConversationMessageDestructionTimeout]
    fileprivate let userSession: ZMUserSession

    private let collectionViewLayout = UICollectionViewFlowLayout()

    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
    }()

    // MARK: - Initialization

    public init(conversation: ZMConversation, items: [ZMConversationMessageDestructionTimeout], userSession: ZMUserSession) {
        self.conversation = conversation
        self.items = items
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "group_details.timeout_options_cell.title".localized.uppercased()
        navigationItem.rightBarButtonItem = navigationController?.closeItem()

        configureSubviews()
        configureConstraints()
    }

    private func configureSubviews() {

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(scheme: .contentBackground)
        collectionView.alwaysBounceVertical = true

        collectionViewLayout.minimumLineSpacing = 0

        CheckmarkCell.register(in: collectionView)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SectionHeader")

    }

    private func configureConstraints() {

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

    }

}

// MARK: - Table View

extension ConversationTimeoutOptionsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)

        cell.title = item.displayString
        cell.showCheckmark = item == conversation.destructionTimeout
        cell.showSeparator = indexPath.row < (items.count - 1)

        return cell

    }

    // MARK: Saving Changes

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        collectionView.deselectItem(at: indexPath, animated: true)
        let newTimeout = items[indexPath.row]

        userSession.enqueueChanges {
            self.conversation.updateMessageDestructionTimeout(timeout: newTimeout)
            self.collectionView.reloadData()
        }

    }

    // MARK: Layout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 32)
    }

}
