//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


import UIKit


@objc final class ProfileHeaderViewModel: NSObject {

    let userDetailViewModel: UserNameDetailViewModel
    let profileViewControllerContext: ProfileViewControllerContext?
    let navigationControllerViewControllerCount: Int?

    init(user: ZMBareUser?,
         fallbackName fallback: String,
         addressBookName: String?,
         navigationControllerViewControllerCount: Int?,
         profileViewControllerContext: ProfileViewControllerContext? = nil) {
        self.navigationControllerViewControllerCount = navigationControllerViewControllerCount
        self.profileViewControllerContext = profileViewControllerContext
        self.userDetailViewModel = UserNameDetailViewModel(
            user: user,
            fallbackName: fallback,
            addressBookName: addressBookName
        )
    }

}
