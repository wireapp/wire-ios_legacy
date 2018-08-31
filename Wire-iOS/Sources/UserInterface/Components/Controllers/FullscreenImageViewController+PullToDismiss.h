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


#import "FullscreenImageViewController.h"

@interface FullscreenImageViewController ()
@property (nonatomic) BOOL isDraggingImage;
@property (nonatomic) CGAffineTransform imageViewStartingTransform;
@property (nonatomic) CGPoint imageDragStartingPoint;
@property (nonatomic) UIOffset imageDragOffsetFromActualTranslation;
@property (nonatomic) UIOffset imageDragOffsetFromImageCenter;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIAttachmentBehavior* attachmentBehavior;
@property (nonatomic) CGRect initialImageViewBounds;
@property (nonatomic) CGPoint initialImageViewCenter;

@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@end

@interface FullscreenImageViewController (PullToDismiss) <UIGestureRecognizerDelegate>
- (void)dismissingPanGestureRecognizerPanned:(UIPanGestureRecognizer *)panner;
@end
