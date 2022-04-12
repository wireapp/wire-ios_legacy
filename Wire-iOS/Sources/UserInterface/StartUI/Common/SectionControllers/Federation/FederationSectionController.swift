//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSyncEngine

class FederationSectionController: SearchSectionController {

    var users = [ZMSearchUser]()

    weak var delegate: SearchSectionControllerDelegate?
    weak var collectionView: UICollectionView?

    override var isHidden: Bool {
        return users.isEmpty
    }

    override var sectionTitle: String {
        L10n.Localizable.Peoplepicker.Header.federation
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        guard let collectionView = collectionView else {
            return
        }

        UserCell.register(in: collectionView)

        self.collectionView = collectionView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)
        let user = users[indexPath.row]
        cell.configure(with: user, selfUser: ZMUser.selfUser())
        cell.accessoryIconView.isHidden = true
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        delegate?.searchSectionController(self, didSelectUser: user, at: indexPath)
    }

}
