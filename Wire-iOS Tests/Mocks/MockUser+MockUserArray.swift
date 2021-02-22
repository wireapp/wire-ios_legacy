//
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
@testable import Wire

extension MockUser {


    /// Get the first MockUser form the mockUsers array and cast to MockUser.
    ///
    /// Notice: actually mockUsers() returns [MockUser], not [ZMUser].
    ///
    /// - Returns: the first MockUser object in the mockUsers array
    class func firstMockUser() -> MockUser {
        let user = MockUser.mockUsers()[0]
        return (user as Any as? MockUser)!
    }
}
