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

import Foundation
import UIKit
import WireSyncEngine

final class ReceiptOptionsSectionController: GroupDetailsSectionController {


    private let emptySectionHeaderHeight: CGFloat = 24

    let cellReuseIdentifier: String = GroupDetailsReceiptOptionsCell.zm_reuseIdentifier

    // MARK: - Properties

    private let conversation: GroupDetailsConversationType
    private let syncCompleted: Bool

    private var footerView = SectionFooter(frame: .zero)
    private weak var presentingViewController: UIViewController?

    override var isHidden: Bool {
        return !SelfUser.current.canModifyReadReceiptSettings(in: conversation)
    }

    init(conversation: GroupDetailsConversationType,
        syncCompleted: Bool,
        collectionView: UICollectionView,
        presentingViewController: UIViewController) {
        self.conversation = conversation
        self.syncCompleted = syncCompleted
        self.presentingViewController = presentingViewController

        SectionFooter.register(collectionView: collectionView)
    }

    // MARK: - Collection View

    override var sectionTitle: String {
        return ""
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView.flatMap(GroupDetailsReceiptOptionsCell.register)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }


    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! GroupDetailsReceiptOptionsCell

        cell.configure(with: conversation)
        cell.action = { [weak self] enabled in
            guard let userSession = ZMUserSession.shared(), let conversation = self?.conversation else { return }

            cell.isUserInteractionEnabled = false
            (conversation as? ZMConversation)?.setEnableReadReceipts(enabled, in: userSession, { result in
                cell.isUserInteractionEnabled = true

                switch result {
                case .failure(_):
                    cell.configure(with: conversation)
                    self?.presentingViewController?.present(UIAlertController.checkYourConnection(), animated: true)
                default:
                    break
                }
            })

        }

        cell.showSeparator = false
        cell.isUserInteractionEnabled = syncCompleted
        cell.alpha = syncCompleted ? 1 : 0.48

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    ///MARK: - header

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: emptySectionHeaderHeight)
    }

    ///MARK: - footer

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {

        footerView.titleLabel.text = "group_details.receipt_options_cell.description".localized
        footerView.size(fittingWidth: collectionView.bounds.width)
        return footerView.bounds.size
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else { return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)}

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = "group_details.receipt_options_cell.description".localized
        return view
    }

}
