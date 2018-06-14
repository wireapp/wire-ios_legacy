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

protocol GroupOptionsSectionControllerDelegate: class {
    func presentTimeoutOptions(animated: Bool)
    func presentGuestOptions(animated: Bool)
}

class GroupOptionsSectionController: GroupDetailsSectionController {

    private weak var delegate: GroupOptionsSectionControllerDelegate?
    private let conversation: ZMConversation
    private let syncCompleted: Bool

    private let guestsOptionsIndex = 0
    private let timeoutOptionsIndex = 1

    init(conversation: ZMConversation, delegate: GroupOptionsSectionControllerDelegate, syncCompleted: Bool) {
        self.delegate = delegate
        self.conversation = conversation
        self.syncCompleted = syncCompleted
    }

    // MARK: - Collection View

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(GroupDetailsGuestOptionsCell.register)
        collectionView.flatMap(GroupDetailsTimeoutOptionsCell.register)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 32)
    }

    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch indexPath.row {
        case guestsOptionsIndex:
            let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsGuestOptionsCell.self, for: indexPath)
            cell.showSeparator = true
            cell.isOn = conversation.allowGuests
            cell.isUserInteractionEnabled = syncCompleted
            cell.alpha = syncCompleted ? 1 : 0.48
            return cell

        case timeoutOptionsIndex:
            let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsTimeoutOptionsCell.self, for: indexPath)
            cell.showSeparator = false
            cell.configure(with: conversation)
            cell.isUserInteractionEnabled = syncCompleted
            cell.alpha = syncCompleted ? 1 : 0.48
            return cell

        default:
            fatal("Invalid options cell index \(indexPath.row)")
        }

    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch indexPath.row {
        case guestsOptionsIndex:
            delegate?.presentGuestOptions(animated: true)
        case timeoutOptionsIndex:
            delegate?.presentTimeoutOptions(animated: true)
        default:
            break
        }

    }

}
