//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import "ConversationContentViewController+PinchZoom.h"
#import "ConversationContentViewController+Private.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "Wire-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@import WireSyncEngine;
@import WireDataModel;

@implementation ConversationContentViewController (GestureRecognizerDelegate)

- (nullable id<ZMConversationMessage>)messageAtPoint:(CGPoint)point
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath == nil || indexPath.row >= (NSInteger)self.dataSource.messages.count) {
        return nil;
    }
    id<ZMConversationMessage> message = [self.dataSource.messages objectAtIndex:indexPath.section];
    return message;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint locationOfTouch = [touch locationInView:self.tableView];
    id<ZMConversationMessage> message = [self messageAtPoint:locationOfTouch];
    return message != nil &&
           [Message isImageMessage:message] &&
           message.imageMessageData != nil &&
           message.imageMessageData.isDownloaded;
}

- (void)onPinchZoom:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    //no-op
}

@end

NS_ASSUME_NONNULL_END
