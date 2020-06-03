
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

extension UInt64 {
    private static let MaxFileSize: UInt64 = 26214400 // 25 megabytes (25 * 1024 * 1024)
    private static let MaxTeamFileSize: UInt64 = 104857600 // 100 megabytes (100 * 1024 * 1024)
    
    public static func uploadFileSizeLimit(hasTeam: Bool) -> UInt64 {
        return hasTeam ? MaxTeamFileSize : MaxFileSize
    }

}
