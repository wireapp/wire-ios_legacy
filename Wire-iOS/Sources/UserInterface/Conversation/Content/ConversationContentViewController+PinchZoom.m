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
#import "MediaAsset.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "Wire-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@import WireSyncEngine;
@import WireDataModel;

@implementation ConversationContentViewController (GestureRecognizerDelegate)

- (nullable id<ZMConversationMessage>)messageAtPoint:(CGPoint)point
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (indexPath == nil || indexPath.row >= (NSInteger)self.messageWindow.messages.count) {
        return nil;
    }
    id<ZMConversationMessage> message = [self.messageWindow.messages objectAtIndex:indexPath.row];
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
    // TODO: restore pinch to zoom
//    switch(pinchGestureRecognizer.state) {
//        case UIGestureRecognizerStateBegan:
//        {
//            CGPoint locationOfTouch = [pinchGestureRecognizer locationInView:self.tableView];
//            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:locationOfTouch];
//            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//            id<ZMConversationMessage> message = [self.messageWindow.messages objectAtIndex:indexPath.row];
//
//            if (![cell isKindOfClass:[ImageMessageCell class]]) {
//                return;
//            }
//
//            ImageMessageCell *imageCell = (ImageMessageCell *)cell;
//            self.pinchImageCell = imageCell;
//            CGRect imageFrame = [self.view.window convertRect:imageCell.fullImageView.bounds fromView:imageCell.fullImageView];
//
//            id<MediaAsset> image = imageCell.fullImageView.mediaAsset;
//            self.initialPinchLocation = [pinchGestureRecognizer locationInView:self.view];
//
//            self.dimView = [[UIView alloc] initWithFrame:self.view.window.bounds];
//            self.dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//            self.dimView.backgroundColor = [UIColor blackColor];
//            self.dimView.alpha = 0.0f;
//            [self.view.window addSubview:self.dimView];
//
//            self.pinchImageView = [[FLAnimatedImageView alloc] initWithFrame:imageFrame];
//            [self.pinchImageView setMediaAsset:image];
//            self.pinchImageView.contentMode = UIViewContentModeScaleAspectFit;
//            self.pinchImageView.clipsToBounds = YES;
//            self.pinchImageView.image = [UIImage imageWithData:message.imageMessageData.imageData];
//            [self.view.window addSubview:self.pinchImageView];
//
//            imageView.hidden = YES;
//        }
//            break;
//        case UIGestureRecognizerStateChanged:
//        {
//            CGFloat scale = MAX(pinchGestureRecognizer.scale, 1.0f);
//            CGPoint newLocation = [pinchGestureRecognizer locationInView:self.view];
//
//            CGAffineTransform translation = CGAffineTransformMakeTranslation(newLocation.x - self.initialPinchLocation.x, newLocation.y - self.initialPinchLocation.y);
//
//            self.pinchImageView.transform = CGAffineTransformScale(translation, scale, scale);
//
//            self.dimView.alpha = MIN(1.0f, (scale - 1.0f) / 2.0f) * 0.56f + 0.16f;
//        }
//            break;
//        case UIGestureRecognizerStateEnded:
//        case UIGestureRecognizerStateFailed:
//        case UIGestureRecognizerStateCancelled:
//        {
//            [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.2 animations:^{
//                self.pinchImageView.transform = CGAffineTransformIdentity;
//                self.dimView.alpha = 0.0f;
//            } completion:^(BOOL finished) {
//                [self.pinchImageView removeFromSuperview];
//                self.pinchImageView = nil;
//                [self.dimView removeFromSuperview];
//                self.dimView = nil;
//                self.pinchImageCell.fullImageView.hidden = NO;
//            }];
//        }
//            break;
//        default:
//            break;
//    }
}

@end

NS_ASSUME_NONNULL_END
