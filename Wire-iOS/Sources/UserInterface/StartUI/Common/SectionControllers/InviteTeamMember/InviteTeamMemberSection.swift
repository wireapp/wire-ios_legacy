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
import WireDataModel

protocol InviteTeamMemberSectionDelegate: class {
    func inviteSectionDidRequestTeamManagement()
}

final class InviteTeamMemberSection: NSObject, CollectionViewSectionController {

    var team: Team?
    weak var delegate: InviteTeamMemberSectionDelegate?

    init(team: Team?) {
        super.init()
        self.team = team
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(InviteTeamMemberCell.self, forCellWithReuseIdentifier: InviteTeamMemberCell.zm_reuseIdentifier)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    var isHidden: Bool {
        return team?.members.count > 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: InviteTeamMemberCell.zm_reuseIdentifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.inviteSectionDidRequestTeamManagement()
    }

}
