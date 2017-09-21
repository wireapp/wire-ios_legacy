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


#import "ContactsViewController+InvitationStatus.h"
#import "ContactsViewController+Private.h"
#import "ContactsDataSource.h"
#import "ContactsCell.h"

@import WireExtensionComponents;



@implementation ContactsViewController (InvitationStatus)

// TODO
//- (void)invitationStatusChanged:(ZMInvitationStatusChangedNotification *)note
//{
//    BOOL shouldUpdateCell = note.newStatus == ZMInvitationStatusPending || note.newStatus == ZMInvitationStatusFailed;
// 
//    NSIndexPath *index = [self indexPathForNotification:note];
//    if (index && shouldUpdateCell) {
//        ContactsCell *cell = (ContactsCell *)[self.tableView cellForRowAtIndexPath:index];
//        if (cell && [cell isKindOfClass:[ContactsCell class]]) {
//            [cell invitationStatusChanged:note];
//            if ([self.contentDelegate respondsToSelector:@selector(contactsViewController:shouldDisplayActionButtonForUser:)]) {
//                cell.actionButton.hidden = ! [self.contentDelegate contactsViewController:self shouldDisplayActionButtonForUser:[self.dataSource userAtIndexPath:index]];
//            }
//        }
//    }
//}
//
//- (NSIndexPath *)indexPathForNotification:(ZMInvitationStatusChangedNotification *)note
//{
//    NSArray *visibleRowPaths = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *indexPath in visibleRowPaths) {
//        ZMSearchUser *searchUser = [self.dataSource userAtIndexPath:indexPath];
//        if ([searchUser.contact.emailAddresses containsObject:note.emailAddress] ||
//            [searchUser.contact.phoneNumbers containsObject:note.phoneNumber]) {
//            return indexPath;
//        }
//    }
//    return nil;
//}

@end
