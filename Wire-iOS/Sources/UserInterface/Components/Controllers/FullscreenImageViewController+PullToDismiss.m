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


#import "FullscreenImageViewController+PullToDismiss.h"
#import "FullscreenImageViewController+internal.h"

@interface DynamicsProxy : NSObject <UIDynamicItem>
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@end

@implementation DynamicsProxy

@end


@interface FullscreenImageViewController (PanGestureRecognizerDelegate) <UIGestureRecognizerDelegate>
@end


@implementation FullscreenImageViewController (PullToDismiss)

- (void)dismissingPanGestureRecognizerPanned:(UIPanGestureRecognizer *)panner
{

    CGPoint translation = [panner translationInView:panner.view];
    CGPoint locationInView = [panner locationInView:panner.view];
    CGPoint velocity = [panner velocityInView:panner.view];
    CGFloat vectorDistance = sqrtf(powf(velocity.x, 2) + powf(velocity.y, 2));
    
    if (panner.state == UIGestureRecognizerStateBegan) {
        self.isDraggingImage = CGRectContainsPoint(self.imageView.frame, locationInView);
        if (self.isDraggingImage) {
            [self initiateImageDragFromLocation:locationInView translationOffset:UIOffsetZero];
        }
    }
    else if (panner.state == UIGestureRecognizerStateChanged) {
        if (self.isDraggingImage) {
            CGPoint newAnchor = self.imageDragStartingPoint;
            newAnchor.x += translation.x + self.imageDragOffsetFromActualTranslation.horizontal;
            newAnchor.y += translation.y + self.imageDragOffsetFromActualTranslation.vertical;
            self.attachmentBehavior.anchorPoint = newAnchor;
            [self updateBackgroundColorWithImageViewCenter:self.imageView.center];
        } else {
            self.isDraggingImage = CGRectContainsPoint(self.imageView.frame, locationInView);
            if (self.isDraggingImage) {
                UIOffset translationOffset = UIOffsetMake(-1 * translation.x, -1 * translation.y);
                [self initiateImageDragFromLocation:locationInView translationOffset:translationOffset];
            }
        }
    }
    else {
        if (vectorDistance > 300 && fabs(translation.y) > 100) {
            if (self.isDraggingImage) {
                [self dismissImageFlickingWithVelocity:velocity];
            } else {
                [self dismissWithCompletion:nil];
            }
        }
        else {
            [self cancelCurrentImageDragAnimated:YES];
        }
    }
}

#pragma mark - Dynamic Image Dragging

- (void)initiateImageDragFromLocation:(CGPoint)panGestureLocationInView translationOffset:(UIOffset)translationOffset
{
    [self setupSnapshotBackgroundView];
    [self showChrome:NO];
    
    self.initialImageViewCenter = self.imageView.center;
    CGPoint nearLocationInView = CGPointMake((panGestureLocationInView.x - self.initialImageViewCenter.x) * 0.1 + self.initialImageViewCenter.x,
                                             (panGestureLocationInView.y - self.initialImageViewCenter.y) * 0.1 + self.initialImageViewCenter.y);
    
    self.imageDragStartingPoint = nearLocationInView;
    self.imageDragOffsetFromActualTranslation = translationOffset;
    
    CGPoint anchor = self.imageDragStartingPoint;
    UIOffset offset = UIOffsetMake(nearLocationInView.x - self.initialImageViewCenter.x, nearLocationInView.y - self.initialImageViewCenter.y);
    self.imageDragOffsetFromImageCenter = offset;
    
    // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
    DynamicsProxy *proxy = [DynamicsProxy new];
    self.imageViewStartingTransform = self.imageView.transform;
    proxy.center = self.imageView.center;
    self.initialImageViewBounds = [self.view convertRect:self.imageView.bounds fromView:self.imageView];
    proxy.bounds = self.initialImageViewBounds;

    self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:proxy
                                                        offsetFromCenter:offset
                                                        attachedToAnchor:anchor];
    self.attachmentBehavior.damping = 1;
    @weakify(self);
    self.attachmentBehavior.action = ^() {
        @strongify(self);
        self.imageView.center = CGPointMake(self.imageView.center.x,
                                            proxy.center.y);
        self.imageView.transform = CGAffineTransformConcat(proxy.transform, self.imageViewStartingTransform);
    };
    [self.animator addBehavior:self.attachmentBehavior];

    UIDynamicItemBehavior *modifier = [[UIDynamicItemBehavior alloc] initWithItems:@[proxy]];
    modifier.density = 10000000;
    modifier.resistance = 1000;
    modifier.elasticity = 0;
    modifier.friction = 0;
    [self.animator addBehavior:modifier];
}

- (void)cancelCurrentImageDragAnimated:(BOOL)animated
{
    [self.animator removeAllBehaviors];
    self.attachmentBehavior = nil;
    self.isDraggingImage = NO;
    
    if (animated == NO) {
        self.imageView.transform = self.imageViewStartingTransform;
        self.imageView.center = self.initialImageViewCenter;
    } else {
        [UIView animateWithDuration:0.35
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if (self.isDraggingImage == NO) {
                                 self.imageView.transform = self.imageViewStartingTransform;
                                 [self updateBackgroundColorWithProgress:0];
                                 if (self.scrollView.dragging == NO && self.scrollView.decelerating == NO) {
                                     self.imageView.center = self.initialImageViewCenter;
                                 }
                             }
                         } completion:nil];
    }
}

- (void)dismissImageFlickingWithVelocity:(CGPoint)velocity
{
    @weakify(self);
    // Proxy object is used because the UIDynamics messing up the zoom level transform on imageView
    DynamicsProxy *proxy = [DynamicsProxy new];
    proxy.center = self.imageView.center;
    proxy.bounds = self.initialImageViewBounds;
    self.isDraggingImage = NO;

    UIPushBehavior *push = [[UIPushBehavior alloc] initWithItems:@[proxy] mode:UIPushBehaviorModeInstantaneous];
    push.pushDirection = CGVectorMake(velocity.x * 0.1, velocity.y * 0.1);
    [push setTargetOffsetFromCenter:UIOffsetMake(self.attachmentBehavior.anchorPoint.x - self.initialImageViewCenter.x, self.attachmentBehavior.anchorPoint.y - self.initialImageViewCenter.y) forItem:self.imageView];

    push.magnitude = MAX(self.minimumDismissMagnitude, fabs(velocity.y) / 6.0f);

    push.action = ^{
        @strongify(self);
        self.imageView.center = CGPointMake(self.imageView.center.x,
                                            proxy.center.y);

        [self updateBackgroundColorWithImageViewCenter:self.imageView.center];
        if ([self imageViewIsOffscreen]) {
            [UIView animateWithDuration:0.1 animations:^{
                [self updateBackgroundColorWithProgress:1];
            } completion:^(BOOL finished) {
                [self.animator removeAllBehaviors];
                self.attachmentBehavior = nil;
                [self.imageView removeFromSuperview];
                [self dismissWithCompletion:nil];
            }];
        }
    };
    [self.animator removeBehavior:self.attachmentBehavior];
    [self.animator addBehavior:push];
}

- (BOOL)imageViewIsOffscreen
{
    // tiny inset threshold for small zoom
    return ! CGRectIntersectsRect(CGRectInset(self.view.bounds, -10, -10), [self.view convertRect:self.imageView.bounds fromView:self.imageView]);
}

- (void)updateBackgroundColorWithImageViewCenter:(CGPoint)imageViewCenter
{
    CGFloat progress = fabs(imageViewCenter.y - self.initialImageViewCenter.y) / 1000;
    [self updateBackgroundColorWithProgress:progress];
}

- (void)updateBackgroundColorWithProgress:(CGFloat)progress
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIUserInterfaceIdiom interfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    if (UIDeviceOrientationIsLandscape(orientation) && interfaceIdiom == UIUserInterfaceIdiomPhone) {
        return;
    }
    CGFloat newAlpha = 1 - progress;
    if (self.isDraggingImage) {
        newAlpha = MAX(newAlpha, 0.80);
    }

    if (self.snapshotBackgroundView) {
        self.snapshotBackgroundView.alpha = 1 - newAlpha;
    } else {
        self.view.backgroundColor = [self.view.backgroundColor colorWithAlphaComponent:newAlpha];
    }
}

@end


@implementation FullscreenImageViewController (PanGestureRecognizerDelegate)

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGRect imageViewRect = [self.view convertRect:self.imageView.bounds fromView:self.imageView];
    
    // image view is not contained within view
    if (!CGRectContainsRect(CGRectInset(self.view.bounds, -10, -10), imageViewRect)) {
        return NO;
    }
    
    if (gestureRecognizer == self.panRecognizer) {
        // touch is not within image view
        if (!CGRectContainsPoint(imageViewRect, [self.panRecognizer locationInView:self.view])) {
            return NO;
        }
        
        CGPoint offset = [self.panRecognizer translationInView:self.view];
        
        return fabs(offset.y) > fabs(offset.x);
    }
    else {
        return YES;
    }
}

@end

