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


#import "ConversationListViewModel.h"
#import "WireSyncEngine+iOS.h"
@import WireDataModel;
#import "Wire-Swift.h"

void debugLog (NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@implementation ConversationListConnectRequestsItem ///TODO: remove?
@end


@implementation ConversationListViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isFolderEnable = true;

        self.contactRequestsItem = [[ConversationListConnectRequestsItem alloc] init];

        [self updateAllSections];
        [self setupObserversForListReloading];
        [self setupObserversForActiveTeam];
        [self subscribeToTeamsUpdates];
    }
    return self;
}

@end


@implementation ConversationListViewModel (Convenience)

//- (NSIndexPath *)itemPreviousToIndex:(NSUInteger)index section:(NSUInteger)sectionIndex
//{
//    NSArray *section = [self sectionAtIndex:sectionIndex];
//    
//    if (index > 0 && section.count > index - 1) {
//        // Select previous item in section
//        return [NSIndexPath indexPathForItem:index-1 inSection:sectionIndex];
//    }
//    else if (index == 0) {
//        // select last item in previous section
//        return [self lastItemInSectionPreviousTo:sectionIndex];
//    }
//    
//    return nil;
//}
//
//- (NSIndexPath *)lastItemInSectionPreviousTo:(NSUInteger)sectionIndex
//{
//    NSInteger previousSectionIndex = sectionIndex - 1;
//    
//    if (previousSectionIndex < 0) {
//        // we are at the top, so return nil
//        return nil;
//    }
//    
//    NSArray *section = [self sectionAtIndex:previousSectionIndex];
//    if (section != nil) {
//        if (section.count > 0) {
//            return [NSIndexPath indexPathForItem:section.count - 1 inSection:previousSectionIndex];
//        }
//        else {
//            // Recursively move back
//            return [self lastItemInSectionPreviousTo:previousSectionIndex];
//        }
//    }
//    
//    return nil;
//}

@end



void debugLog(NSString *format, ...)
{
    if (DEBUG) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}
