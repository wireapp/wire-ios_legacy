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

final class UserRight {
    static let sharedInstance = UserRight()
    private init() {}

    enum Permission {
        case resetPassword,
             editName,
             editHandle,
             editEmail,
             editPhone,
             editProfilePicture,
             editAccentColor
    }

    class func selfUserIsPermitted(to permission: UserRight.Permission) -> Bool {
        switch permission {
        case .editEmail:
        #if EMAIL_EDITING_DISABLED
            return false
        #else
            ///TODO: wait for DM update
            return true
        #endif
        case .resetPassword:
        ///TODO: For SSO user we don't allow setting or resetting the password
            break
        case .editName,
             .editHandle,
             .editPhone,
             .editProfilePicture,
             .editAccentColor:
            ///TODO: wait for DM update
            return true
        }

        return false
    }
}
