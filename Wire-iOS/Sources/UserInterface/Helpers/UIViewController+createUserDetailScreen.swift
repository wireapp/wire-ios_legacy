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
extension UIViewController {

    /// Return a ProfileHeaderServiceDetailViewController if the user is a serviceUser, otherwise return a ProfileViewController
    ///
    /// - Parameters:
    ///   - user: user to show the detailif
    ///   - conversation: conversation currently displaying
    ///   - profileViewControllerDelegate: a ProfileViewControllerDelegate
    ///   - navigationControllerDelegate: a ProfileNavigationControllerDelegate
    /// - Returns: if the user is a serviceUser, return a ProfileHeaderServiceDetailViewController. if the user not a serviceUser, return a ProfileViewController
    @objc static func createUserDetailViewController(user: ZMUser, conversation: ZMConversation, profileViewControllerDelegate: ProfileViewControllerDelegate, navigationControllerDelegate: ProfileNavigationControllerDelegate? = nil) -> UIViewController {
        if user.isServiceUser {
            let profileHeaderServiceDetailViewController = ProfileHeaderServiceDetailViewController(serviceUser: user, conversation: conversation)
            profileHeaderServiceDetailViewController.profileViewControllerDelegate = profileViewControllerDelegate
            return profileHeaderServiceDetailViewController
        } else {
            let profileViewController = ProfileViewController(user: user, conversation: conversation)
            profileViewController?.delegate = profileViewControllerDelegate
            profileViewController?.navigationControllerDelegate = navigationControllerDelegate
            return profileViewController!
        }
    }
}
