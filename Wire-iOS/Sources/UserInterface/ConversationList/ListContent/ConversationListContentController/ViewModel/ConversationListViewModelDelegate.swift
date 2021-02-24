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

import DifferenceKit
import WireDataModel

/// a item which can be presented in the conversaton list
protocol ConversationListItem: NSObject {}

extension ZMConversation: ConversationListItem {}

// Placeholder for conversation requests item
final class ConversationListConnectRequestsItem: NSObject, ConversationListItem {}

protocol ConversationListViewModelDelegate: class {
    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?)

    func listViewModelShouldBeReloaded()

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool)

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool)

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: Int)

    func reload<C>(
    using stagedChangeset: StagedChangeset<C>,
    interrupt: ((Changeset<C>) -> Bool)?,
    setData: (C?) -> Void
    )
}

protocol ConversationListViewModelRestorationDelegate: class {
    func listViewModel(_ model: ConversationListViewModel?, didRestoreFolderEnabled enabled: Bool)
}
