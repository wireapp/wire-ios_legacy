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


#import "PeopleSelection.h"
#import "WireSyncEngine+iOS.h"

@interface PeopleSelection ()
@property (nonatomic, strong) NSMutableSet *selectedUsersBacking;
@end

@implementation PeopleSelection

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectedUsersBacking = [NSMutableSet set];
    }
    return self;
}

- (void)addUserToSelectedResults:(ZMUser *)user
{
    [self.peopleInputController addTokenForUser:user];
    [self.selectedUsersBacking addObject:user];
    
    [self selectedUsersUpdated];
}

- (void)removeUserFromSelectedResults:(ZMUser *)user
{
    [self.selectedUsersBacking removeObject:user];
    [self.peopleInputController removeTokenForUser:user];
    
    [self selectedUsersUpdated];
}

- (NSSet *)selectedUsers
{
    return [self.selectedUsersBacking copy];
}

- (void)selectedUsersUpdated
{
    if ([self.delegate respondsToSelector:@selector(selectedUsersUpdated:)]) {
        [self.delegate selectedUsersUpdated:self];
    }
}

#pragma mark - PeopleInputControllerSelectionDelegate

- (void)peopleInputController:(PeopleInputController *)controller changedPresentedDirectoryResultsTo:(NSSet *)directoryResults
{
    if ([self.selectedUsersBacking isEqualToSet:directoryResults]) {
        return; // No change
    }
    
    NSSet *previousSelection = [self.selectedUsersBacking copy];
    [self.selectedUsersBacking setSet:directoryResults];
    
    if ([self.delegate respondsToSelector:@selector(peopleSelection:didDeselectUsers:)]) {
        NSMutableSet *removedUsers = [previousSelection mutableCopy];
        [removedUsers minusSet:directoryResults];
        
        if (removedUsers.count > 0) {
            [self.delegate peopleSelection:self didDeselectUsers:removedUsers];
        }
    }

    if ([self.delegate respondsToSelector:@selector(peopleSelection:didSelectUsers:)]) {
        NSMutableSet *addedUsers = [directoryResults mutableCopy]; 
        [addedUsers minusSet:previousSelection];
    
        if (addedUsers.count > 0) {
            [self.delegate peopleSelection:self didSelectUsers:addedUsers];
        }
    }

    [self selectedUsersUpdated];
}

@end
