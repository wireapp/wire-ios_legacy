//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

/// A utility class to help trigger downloading team metadata for the self user.
///
/// It ensures the trigger is not made more than once within a specified time interval.

final class TeamMetadataRefresher {

    // MARK: - Properties

    /// The minimum interval of time between consecutive refreshes. Defaults to 24 hours.

    let refreshInterval: TimeInterval

    // MARK: - Private Properties

    private var dateOfLastRefresh: Date?

    private var isTimeoutExpired: Bool {
        guard let dateOfLastRefresh = dateOfLastRefresh else { return true }
        let intervalSinceLastRefresh = -dateOfLastRefresh.timeIntervalSinceNow
        return intervalSinceLastRefresh > refreshInterval
    }

    // MARK: - Init

    init(refreshInterval: TimeInterval = .oneDay) {
        self.refreshInterval = refreshInterval
    }

    // MARK: - Methods

    /// Triggers a refresh of the team metadata of the self user, if needed.

    func triggerRefreshIfNeeded() {
        guard
            let selfUser = SelfUser.provider?.selfUser,
            selfUser.isTeamMember,
            isTimeoutExpired
        else {
            return
        }

        selfUser.refreshTeamData()
        dateOfLastRefresh = Date()
    }

}
