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

extension ConversationMessageWindowTableViewAdapter: UITableViewDataSource {

    /**
     * Creates a new section controller for the message, when the adapter cannot find one in the cache.
     */

    @objc(buildSectionControllerForMessage:)
    func buildSectionController(for message: ZMConversationMessage) -> ConversationMessageSectionController {
        return messageWindow.sectionController(for: message, firstUnreadMessage: firstUnreadMessage)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.messageWindow.messages.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionController = self.sectionController(at: section, in: tableView)!
        return sectionController.numberOfCells
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionController = self.sectionController(at: indexPath.section, in: tableView)!
        return sectionController.makeCell(for: tableView, at: indexPath)
    }
}
