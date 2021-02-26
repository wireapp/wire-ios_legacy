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
import WireDataModel

protocol UserRightInterface {
    static func selfUserIsPermitted(to permission: UserRight.Permission) -> Bool
}

final class UserRight: UserRightInterface {
    enum Permission {
        case resetPassword,
             editName,
             editHandle,
             editEmail,
             editPhone,
             editProfilePicture,
             editAccentColor
    }

    static func selfUserIsPermitted(to permission: UserRight.Permission) -> Bool {
        let selfUser = ZMUser.selfUser()
        let usesCompanyLogin = selfUser?.usesCompanyLogin == true

        switch permission {
        case .editEmail:
        #if EMAIL_EDITING_DISABLED
            return false
        #else
            return isProfileEditable || !usesCompanyLogin
        #endif
        case .resetPassword:
            return isProfileEditable || !usesCompanyLogin
        case .editProfilePicture:
            return true // NOTE we always allow editing for now since settting profile picture is not yet supported by SCIM
        case .editName,
             .editHandle,
             .editPhone,
             .editAccentColor:
			return isProfileEditable
        }
    }

    private static var isProfileEditable: Bool {
        return ZMUser.selfUser()?.managedByWire ?? true
    }
}
