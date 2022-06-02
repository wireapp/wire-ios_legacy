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

class ConversationCreateGuestsSectionController: ConversationCreateSectionController {

    typealias Cell = ConversationCreateGuestsCell

    var toggleAction: ((Bool) -> Void)?

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(Cell.register)
        headerHeight = 40
        footerText = "conversation.create.guests.subtitle".localized
    }
}

extension ConversationCreateGuestsSectionController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: Cell.self, for: indexPath)
        self.cell = cell
        cell.setUp()
        cell.configure(with: values)
        cell.action = toggleAction
        return cell
    }
}
