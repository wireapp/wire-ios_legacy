////
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

import Foundation
import UIKit
import WireDataModel
import WireSyncEngine

final class ConversationNotificationOptionsViewController: UIViewController {

    private var items: [MutedMessageTypes] = [.none, .regular, .all]

    private let conversation: ZMConversation
    private let userSession: ZMUserSession
    private var observerToken: Any! = nil

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
        observerToken = ConversationChangeInfo.add(observer: self, for: conversation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let titleLabel = DynamicFontLabel(
            text: L10n.Localizable.GroupDetails.NotificationOptionsCell.title,
            fontSpec: .headerSemiboldFont,
            color: SemanticColors.Label.textDefault)
        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = navigationController?.updatedCloseItem()
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.NotificationConversationSettings.CloseButton.description

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
        collectionView.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }

    private func configureConstraints() {

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.fitIn(view: view)
    }
}

// MARK: - Table View

extension ConversationNotificationOptionsViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = items[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: CheckmarkCell.self, for: indexPath)

        cell.title = item.localizationKey?.localized
        cell.showCheckmark = item == conversation.mutedMessageTypes
        cell.showSeparator = indexPath.row < (items.count - 1)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "SectionHeader", for: indexPath)
            return view
        } else {
            let dequeuedView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                               withReuseIdentifier: "SectionFooter",
                                                                               for: indexPath)

            guard let view = dequeuedView as? SectionFooter else { return UICollectionReusableView(frame: .zero) }
            view.titleLabel.text = "group_details.notification_options_cell.description".localized
            return view
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let dequeuedView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                           withReuseIdentifier: "SectionFooter",
                                                                           for: IndexPath(item: 0, section: section))

        guard let view = dequeuedView as? SectionFooter else { return .zero }

        view.titleLabel.text = "group_details.notification_options_cell.description".localized
        view.size(fittingWidth: collectionView.bounds.width)
        return view.bounds.size
    }

    // MARK: Saving Changes

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let selectedItem = items[indexPath.row]

        guard selectedItem != conversation.mutedMessageTypes else { return }
        updateMutedMessageTypes(selectedItem)
    }

    private func updateMutedMessageTypes(_ types: MutedMessageTypes) {

        userSession.perform {
            self.conversation.mutedMessageTypes = types
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

extension ConversationNotificationOptionsViewController: ZMConversationObserver {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.mutedMessageTypesChanged else { return }
        collectionView.reloadData()
    }
}

extension MutedMessageTypes {

    var localizationKey: String? {
        let base = "meta.menu.configure_notification.button_"
        switch self {
        case .none:         return base + "everything"
        case .regular:      return base + "mentions_and_replies"
        case .all:          return base + "nothing"
        default:            return nil
        }
    }
}
