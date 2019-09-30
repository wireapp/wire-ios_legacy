
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

@objc
protocol ConversationListViewModelDelegate: NSObjectProtocol {
    func listViewModelShouldBeReloaded()
    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: UInt)
    /// Delegate MUST call the updateBlock in appropriate place (e.g. collectionView performBatchUpdates:) to update the model.

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: UInt, usingBlock updateBlock: () -> (), with changedIndexes: ZMChangedIndexes?)
    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: Any?)

    func listViewModel(_ model: ConversationListViewModel?, didUpdateConversationWithChange change: ConversationChangeInfo?)

    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool)
}


protocol ConversationListViewModelRestorationDelegate: class {
    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool)
}
