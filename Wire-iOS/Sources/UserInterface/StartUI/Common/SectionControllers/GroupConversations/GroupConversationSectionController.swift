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

final class GroupConversationsSectionController: SearchSectionController {

    var groupConversations: [ZMConversation] = []
    var title: String = ""
    weak var delegate: SearchSectionControllerDelegate?

    override var isHidden: Bool {
        return groupConversations.isEmpty
    }

    override var sectionTitle: String {
        return title
    }

    override var sectionAccessibilityIdentifier: String {
        return "label.search.group_conversation"
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(GroupConversationCell.self, forCellWithReuseIdentifier: GroupConversationCell.zm_reuseIdentifier)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupConversations.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let conversation = groupConversations[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupConversationCell.zm_reuseIdentifier, for: indexPath) as! GroupConversationCell

        cell.configure(conversation: conversation)
        cell.separator.isHidden = (groupConversations.count - 1) == indexPath.row

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let conversation = groupConversations[indexPath.row]

        delegate?.searchSectionController(self, didSelectConversation: conversation, at: indexPath)
    }


}
