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
import WireDataModel

// MARK: - For Swift with suffix optional parameter support
extension String {

    /// Return a file name with length <= 255 - 4(reserve for extension) - 37(reserve for WireDataModel UUID prefix) characters with a optional suffix
    ///
    /// - Parameter suffix: suffix of the file name.
    /// - Returns: a filename <= (214 + length of suffix) characters
    static func filenameForSelfUser(suffix: String? = nil) -> String {
        return ZMUser.selfUser().filename(suffix: suffix)
    }

}
