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
import WireDataModel
import WireSyncEngine

private enum Item {
    case supportedValue(MessageDestructionTimeoutValue)
    case unsupportedValue(MessageDestructionTimeoutValue)
    case customValue
}

extension ZMConversation {
    fileprivate var timeoutItems: [Item] {
        var newItems = MessageDestructionTimeoutValue.all.map(Item.supportedValue)

        let groupTimeout = messageDestructionTimeoutValue(for: .groupConversation)
        if case .custom = groupTimeout {
            newItems.append(.unsupportedValue(groupTimeout))
        }

        if Bundle.developerModeEnabled {
            newItems.append(.customValue)
        }

        return newItems
    }
}

final class ConversationTimeoutOptionsViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: SpinnerCompletion?

    fileprivate let conversation: ZMConversation
    fileprivate var items: [Item] = []
    fileprivate let userSession: ZMUserSession
    fileprivate var observerToken: Any! = nil

    weak var dismisser: ViewControllerDismisser?

    private let collectionViewLayout = UICollectionViewFlowLayout()

    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
    }()

    // MARK: - Initialization

    public init(conversation: ZMConversation, userSession: ZMUserSession) {
        self.conversation = conversation
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
        self.updateItems()
        observerToken = ConversationChangeInfo.add(observer: self, for: conversation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "group_details.timeout_options_cell.title".localized(uppercased: true)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.SelfDeletingMessagesConversationSettings.CloseButton.description

        configureSubviews()
        configureConstraints()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    private func configureSubviews() {

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = SemanticColors.View.backgroundDefault
        collectionView.alwaysBounceVertical = true

        collectionViewLayout.minimumLineSpacing = 0

        CheckmarkCell.register(in: collectionView)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader")

    }

    private func configureConstraints() {

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.fitIn(view: view)
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
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)

        func configure(_ cell: CheckmarkCell, for value: MessageDestructionTimeoutValue, disabled: Bool) {
            cell.title = value.displayString
            cell.disabled = disabled
            cell.showCheckmark = conversation.messageDestructionTimeoutValue(for: .groupConversation) == value
        }

        switch item {
        case .supportedValue(let value):
            configure(cell, for: value, disabled: false)
        case .unsupportedValue(let value):
            configure(cell, for: value, disabled: true)
        case .customValue:
            cell.title = "Custom"
            cell.showCheckmark = false
        }

        cell.showSeparator = indexPath.row < (items.count - 1)

        return cell
    }

    private func updateItems() {
        self.items = conversation.timeoutItems
    }

    private func updateTimeout(_ timeout: MessageDestructionTimeoutValue) {
        let item = CancelableItem(delay: 0.4) { [weak self] in
            self?.isLoadingViewVisible = true
        }

        self.conversation.setMessageDestructionTimeout(timeout, in: userSession) { [weak self] result in
            guard let `self` = self else {
                return
            }

            item.cancel()
            self.isLoadingViewVisible = false

            if case .failure(let error) = result {
                self.handle(error: error)
            }
        }
    }

    private func handle(error: Error) {
        let controller = UIAlertController.checkYourConnection()
        present(controller, animated: true)
    }

    private func requestCustomValue() {
        UIAlertController.requestCustomTimeInterval(over: self) { [weak self] result in

            guard let `self` = self else {
                return
            }

            switch result {
            case .success(let value):
                self.updateTimeout(MessageDestructionTimeoutValue(rawValue: value))
            default:
                break
            }

        }
    }

    // MARK: Saving Changes

    private func canSelectItem(with value: MessageDestructionTimeoutValue) -> Bool {
        let currentValue = conversation.messageDestructionTimeoutValue(for: .groupConversation)
        return value != currentValue

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedItem = items[indexPath.row]

        switch selectedItem {
        case .supportedValue(let value):
            guard canSelectItem(with: value) else {
                break
            }
            updateTimeout(value)
        case .customValue:
            requestCustomValue()
        default:
            break
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

extension ConversationTimeoutOptionsViewController: ZMConversationObserver {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.destructionTimeoutChanged else {
            return
        }
        updateItems()
        collectionView.reloadData()
    }
}
