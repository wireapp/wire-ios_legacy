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

public enum BlacklistReason {
    /// The app version is too old to be supported or has been explicitly blacklisted
    case appVersionBlacklisted

    /// The API versions supported by the client are too old in comparison to the ones supported by the backend
    case clientAPIVersionObsolete

    /// The API versions supported by the backend are too old in comparison to the ones supported by the client
    case backendAPIVersionObsolete
}
