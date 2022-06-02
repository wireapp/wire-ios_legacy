//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension Team {

    // When moving from the initial teams implementation (multiple teams tied to one account) to
    // a multi account setup, we need to delete all local teams. Members will be deleted due to the cascade
    // deletion rule (Team → Member). Conversations will be preserved but their teams realtion will be nullified.
    static func deleteLocalTeamsAndMembers(in context: NSManagedObjectContext) {
        let request = Team.sortedFetchRequest()

        guard let teams = context.fetchOrAssert(request: request) as? [NSManagedObject] else {
            return
        }

        teams.forEach(context.delete)
    }

}
