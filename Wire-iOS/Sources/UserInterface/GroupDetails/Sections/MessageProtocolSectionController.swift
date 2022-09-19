//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel

final class MessageProtocolSectionController: GroupDetailsSectionController {

    typealias Cell = DetailsCollectionViewCell

    // MARK: - Properties

    private let messageProtocol: MessageProtocol

    // MARK: - Life cycle

    init(messageProtocol: MessageProtocol) {
        self.messageProtocol = messageProtocol
        super.init()
    }

    // MARK: - Methods

    override var isHidden: Bool {
        return false
    }

    override var sectionTitle: String? {
        return L10n.Localizable.GroupDetails.MessageProtocol.sectionTile.uppercased()
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        guard let collectionView = collectionView else { return }
        Cell.register(in: collectionView)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard section == 0 else { return 0 }

        switch messageProtocol {
        case .proteus:
            return 1

        case .mls:
            return 2
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Cell.zm_reuseIdentifier,
            for: indexPath
        ) as! Cell

        cell.icon = nil

        switch (messageProtocol, indexPath.row) {
        case (_, 0):
            cell.accessibilityIdentifier = "cell.groupdetails.message_protocol"
            cell.title = L10n.Localizable.GroupDetails.MessageProtocol.title
            cell.status = messageProtocol.name

        case (.mls, 1):
            cell.accessibilityIdentifier = "cell.groupdetails.cipher_suite"
            cell.title = L10n.Localizable.GroupDetails.MessageProtocol.cipherSuite
            cell.status = "MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519 (0x0001)"
            cell.allowMultilineStatus = true

        default:
            break
        }

        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        var size = super.collectionView(
            collectionView,
            layout: collectionViewLayout,
            sizeForItemAt: indexPath
        )

        // We need a little bit more height for the cipher suite text.
        if indexPath.row == 1 {
            size.height += 16
        }

        return size
    }

}

private extension MessageProtocol {

    var name: String {
        switch self {
        case .proteus:
            return "Proteus"

        case .mls:
            return "MLS"
        }
    }

}
