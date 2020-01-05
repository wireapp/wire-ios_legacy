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

@objc
protocol ContactsViewControllerDelegate: NSObjectProtocol {
    
    
    func contactsViewControllerDidCancel(_ controller: ContactsViewController!)
    
    func contactsViewControllerDidNotShareContacts(_ controller: ContactsViewController!)
    
    func contactsViewControllerDidConfirmSelection(_ controller: ContactsViewController!)
}

@objc protocol SearchUserType {
    var user: ZMUser? { get }
}

extension ZMSearchUser: SearchUserType { }

typealias SearchUser = UserType & SearchUserType

@objc
protocol ContactsViewControllerContentDelegate: NSObjectProtocol {
    
    
    func contactsViewController(_ controller: ContactsViewController!, shouldDisplayActionButtonFor user: ZMSearchUser!) -> Bool
    
    func contactsViewController(_ controller: ContactsViewController!, actionButton: UIButton, pressedFor user: ZMSearchUser!)
    
    func contactsViewController(_ controller: ContactsViewController!, didSelect cell: ContactsCell, for user: ZMSearchUser!)
    
    func contactsViewController(_ controller: ContactsViewController!, shouldSelect user: ZMSearchUser!) -> Bool
    
    
    // This API might look strange, but we need it for making all the buttons to have same width
    func actionButtonTitles(for controller: ContactsViewController) -> [String]
    
    func contactsViewController(_ controller: ContactsViewController!, actionButtonTitleIndexFor user: SearchUser) -> Int
}
