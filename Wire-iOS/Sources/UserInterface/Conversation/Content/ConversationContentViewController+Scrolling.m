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


#import "ConversationContentViewController+Scrolling.h"
#import "ConversationContentViewController+Private.h"

// model
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"


@implementation ConversationContentViewController (Scrolling)

- (void)cancelScrolling
{
    CGPoint offset = self.tableView.contentOffset;
    [self.tableView setContentOffset:offset animated:NO];
}

#pragma mark - Scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self removeHighlightsAndMenu];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat bottomOffset = scrollView.contentOffset.y;
    
    if (self.messageWindow.messages.count) {
        [self.delegate conversationContentViewController:self didScrollWithOffsetFromBottom:bottomOffset withLatestMessage:self.messageWindow.messages.lastObject];
    }
    
    // if I am at top, try to load some more messages
    BOOL atTheTop = scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.bounds.size.height;
    
    if (atTheTop) {
        [self expandMessageWindowUp];
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    [self.tableView scrollToBottomAnimated:animated];
}

- (BOOL)scrollToMessage:(id<ZMConversationMessage>)message animated:(BOOL)animated
{
    NSUInteger index = [self.messageWindow.messages indexOfObject:message];
    if (index != NSNotFound) {
        NSInteger rowIndex = [self.tableView numberOfRowsInSection:index] - 1;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:index]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:animated];
    }
    
    return index != NSNotFound;
}

- (BOOL)scrollMessageToBottom:(id<ZMConversationMessage>)message withOffset:(CGFloat)offset
{
    NSUInteger index = [self.messageWindow.messages indexOfObject:message];
    NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:index inSection:0];

    if (messageIndexPath) {
        CGRect rect = [self.tableView rectForRowAtIndexPath:messageIndexPath];
        
        if (! CGRectEqualToRect(rect, CGRectZero)) {
            CGFloat newOffset = rect.origin.y - self.tableView.bounds.size.height + rect.size.height + offset;
            self.tableView.contentOffset = CGPointMake(0, newOffset);
            return YES;
        }
    }
    
    return NO;
}

@end
