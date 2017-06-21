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


#import "SwipeMenuCollectionCell.h"
@import PureLayout;
#import "UIView+Borders.h"
#import "UIView+RemoveAnimations.h"
#import "Wire-Swift.h"



NSString * const SwipeMenuCollectionCellCloseDrawerNotification = @"SwipeMenuCollectionCellCloseDrawerNotification";
NSString * const SwipeMenuCollectionCellIDToCloseKey = @"IDToClose";

@interface SwipeMenuCollectionCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *swipeView;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIView *separatorLine;

@property (nonatomic, assign) BOOL hasCreatedSwipeMenuConstraints;

@property (nonatomic, assign) CGFloat initialDrawerWidth;

@property (nonatomic, assign) CGFloat initialDrawerOffset;
@property (nonatomic, assign) CGPoint initialDragPoint;
@property (nonatomic, assign) BOOL revealDrawerOverscrolled;
@property (nonatomic, assign) BOOL revealAnimationPerforming;
@property (nonatomic, assign) CGFloat scrollingFraction;
@property (nonatomic, assign) CGFloat userInteractionHorizontalOffset;

@property (nonatomic, strong) UIPanGestureRecognizer *revealDrawerGestureRecognizer;
@property (nonatomic, strong) NSLayoutConstraint *swipeViewHorizontalConstraint;
@property (nonatomic, strong) NSLayoutConstraint *menuViewToSwipeViewLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *maxMenuViewToSwipeViewLeftConstraint;

@end


@implementation SwipeMenuCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSwipeMenuCollectionCell];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSwipeMenuCollectionCell];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeAllAnimationsRecursive];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeDrawer:) name:SwipeMenuCollectionCellCloseDrawerNotification object:nil];
    [UIView performWithoutAnimation:^{
        self.separatorLine.alpha = 1.0f;
        self.visualDrawerOffset = 0.0f;
        self.revealDrawerOverscrolled = NO;
        self.userInteractionHorizontalOffset = 0.0f;
        [self setDrawerOpen:NO animated:NO];
    }];
}

- (void)setupSwipeMenuCollectionCell
{
    self.canOpenDrawer = YES;
    self.overscrollFraction = 0.6f;
    self.maxVisualDrawerOffset = 48;
    
    self.swipeView = [[UIView alloc] initForAutoLayout];
    self.swipeView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.swipeView];

    self.menuView = [[UIView alloc] initForAutoLayout];
    self.menuView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.menuView];
    
    self.separatorLine = [[UIView alloc] initForAutoLayout];
    self.separatorLine.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    [self.swipeView addSubview:self.separatorLine];
    self.separatorLine.hidden = self.separatorLineViewDisabled;
    
    self.revealDrawerGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrawerScroll:)];
    self.revealDrawerGestureRecognizer.delegate = self;
    self.revealDrawerGestureRecognizer.delaysTouchesEnded = NO;
    self.revealDrawerGestureRecognizer.delaysTouchesBegan = NO;
    
    [self.contentView addGestureRecognizer:self.revealDrawerGestureRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeDrawer:) name:SwipeMenuCollectionCellCloseDrawerNotification object:nil];

    [self setNeedsUpdateConstraints];
}

- (void)setSeparatorLineViewDisabled:(BOOL)separatorLineViewDisabled
{
    _separatorLineViewDisabled = separatorLineViewDisabled;
    self.separatorLine.hidden = separatorLineViewDisabled;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateConstraints
{
    if (! self.hasCreatedSwipeMenuConstraints) {
        self.hasCreatedSwipeMenuConstraints = YES;
        
        [self.swipeView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView];
        [self.swipeView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView];
        [self.swipeView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        self.swipeViewHorizontalConstraint = [self.swipeView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.contentView withOffset:0];
        
        [self.separatorLine autoSetDimension:ALDimensionWidth toSize:UIScreen.hairline];
        [self.separatorLine autoSetDimension:ALDimensionHeight toSize:25.0f];
        [self.separatorLine autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.swipeView];
        [self.separatorLine autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.menuView];
        
        [self.menuView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.swipeView];
        [self.menuView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.swipeView];
        
        self.menuViewToSwipeViewLeftConstraint = [self.menuView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.swipeView];
        [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
            self.maxMenuViewToSwipeViewLeftConstraint = [self.menuView autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self withOffset:self.maxVisualDrawerOffset];
        }];
    }
    
    [super updateConstraints];
}

- (void)setMaxVisualDrawerOffset:(CGFloat)maxVisualDrawerOffset
{
    _maxVisualDrawerOffset = maxVisualDrawerOffset;
    self.maxMenuViewToSwipeViewLeftConstraint.constant = maxVisualDrawerOffset;
}

- (void)onDrawerScroll:(UIPanGestureRecognizer *)pan
{
    CGPoint location = [pan locationInView:self];
    CGPoint offset = CGPointMake(location.x - self.initialDragPoint.x, location.y - self.initialDragPoint.y);

    if (! self.canOpenDrawer || self.revealAnimationPerforming) {
        return;
    }

    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            // reset gesture state
            [self drawerScrollingStarts];
            
            self.initialDrawerOffset = self.visualDrawerOffset;
            self.initialDragPoint = [pan locationInView:self];
            if (self.visualDrawerOffset == 0) {
                [self sendCellWillOpenNotification];
            }
            break;
        case UIGestureRecognizerStateChanged:
            self.userInteractionHorizontalOffset = offset.x;

            if (self.initialDrawerWidth == 0) {
                self.initialDrawerWidth = self.menuView.bounds.size.width;
            }

            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            [self drawerScrollingEndedWithOffset:offset.x];
            
            if (offset.x + self.initialDrawerOffset > self.bounds.size.width * self.overscrollFraction) { // overscrolled
                if (self.overscrollAction != nil) {
                    self.overscrollAction(self);
                }

                self.separatorLine.alpha = 0.0f;
                [self setVisualDrawerOffset:0 updateUI:NO];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
            else {
                if (self.visualDrawerOffset > self.drawerWidth / 2.0f) {
                    [self setDrawerOpen:YES animated:YES];
                }
                else {
                    [self setDrawerOpen:NO animated:YES];
                }
            }
        }
            break;
        default:
            break;
    }
}

- (CGFloat)drawerWidth
{
    return self.initialDrawerWidth;
}

/**
 *  Apply the apple-style rubber banding on the offset
 *
 *  @param offset    User-interaction offset
 *  @param viewWidth Total container size
 *  @param coef      Coefficient (from very hard (<0.1) to very easy (>0.9))
 *
 *  @return New offset
 */
+ (CGFloat)rubberBandOffset:(CGFloat)offset viewWidth:(CGFloat)viewWidth coefficient:(CGFloat)coef
{
    return (1.0 - (1.0 / ((offset * coef / viewWidth) + 1.0))) * viewWidth;
}

+ (CGFloat)calculateViewOffsetForUserOffset:(CGFloat)offsetX
                              initialOffset:(CGFloat)initialDrawerOffset
                                drawerWidth:(CGFloat)drawerWidth
                                  viewWidth:(CGFloat)viewWidth
{
    if (offsetX + initialDrawerOffset < 0) {
        return [self rubberBandOffset:offsetX + initialDrawerOffset viewWidth:viewWidth coefficient:0.15f];
    }
    else {
        return initialDrawerOffset + offsetX;
    }

    return offsetX;
}

- (void)setUserInteractionHorizontalOffset:(CGFloat)userInteractionHorizontalOffset
{
    _userInteractionHorizontalOffset = userInteractionHorizontalOffset;

    if (self.bounds.size.width == 0) {
        return;
    }
   
    if (self.revealDrawerOverscrolled) {
        if (_userInteractionHorizontalOffset + self.initialDrawerOffset < self.bounds.size.width * self.overscrollFraction) { // overscroll cancelled
            self.revealAnimationPerforming = YES;
            CGPoint animStartInteractionPosition = [self.revealDrawerGestureRecognizer locationInView:self];
            
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.35f animations:^{
                self.scrollingFraction = _userInteractionHorizontalOffset / self.bounds.size.width;
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                // reset gesture state
                CGPoint animEndInteractionPosition = [self.revealDrawerGestureRecognizer locationInView:self];
                
                // we need to adjust the drag point to avoid the jump after the animation was ended
                // between the animation's final state and user new finger position
                CGFloat offsetInteractionBeforeAfterAnimation = animEndInteractionPosition.x - animStartInteractionPosition.x;
                self.initialDragPoint = CGPointMake(offsetInteractionBeforeAfterAnimation + self.initialDragPoint.x, self.initialDragPoint.y);
                self.revealAnimationPerforming = NO;
                
                CGPoint newOffset = CGPointMake(animEndInteractionPosition.x - self.initialDragPoint.x, animEndInteractionPosition.y - self.initialDragPoint.y);
                
                self.scrollingFraction = newOffset.x / self.bounds.size.width;
                [self layoutIfNeeded];
            }];
            
            self.revealDrawerOverscrolled = NO;
        }
    }
    else {
        if (_userInteractionHorizontalOffset + self.initialDrawerOffset > self.bounds.size.width * self.overscrollFraction) { // overscrolled
            
            [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.35f animations:^{
                self.scrollingFraction = 1.0f;
                self.visualDrawerOffset = self.bounds.size.width + self.separatorLine.bounds.size.width;
                [self layoutIfNeeded];
            }];
            
            self.revealDrawerOverscrolled = YES;
        }
        else {
            self.scrollingFraction = _userInteractionHorizontalOffset / self.bounds.size.width;
        }
    }
}

- (void)setScrollingFraction:(CGFloat)scrollingFraction
{
    _scrollingFraction = scrollingFraction;

    self.visualDrawerOffset = [self.class calculateViewOffsetForUserOffset:_scrollingFraction * self.bounds.size.width
                                                             initialOffset:self.initialDrawerOffset
                                                               drawerWidth:self.drawerWidth
                                                                 viewWidth:self.bounds.size.width];
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset
{
    [self setVisualDrawerOffset:visualDrawerOffset updateUI:YES];
}

- (void)setVisualDrawerOffset:(CGFloat)visualDrawerOffset updateUI:(BOOL)doUpdate
{
    if (_visualDrawerOffset == visualDrawerOffset) {
        if (doUpdate) {
            self.swipeViewHorizontalConstraint.constant = _visualDrawerOffset;
            [self checkAndUpdateMaxVisualDrawerOffsetConstraints:visualDrawerOffset];
        }
        return;
    }

    _visualDrawerOffset = visualDrawerOffset;
    if (doUpdate) {
        self.swipeViewHorizontalConstraint.constant = _visualDrawerOffset;
        [self checkAndUpdateMaxVisualDrawerOffsetConstraints:visualDrawerOffset];
    }
}

/// Checks on the @c maxVisualDrawerOffset and switches the prio's of the constraint
- (void)checkAndUpdateMaxVisualDrawerOffsetConstraints:(CGFloat)visualDrawerOffset
{
    if (visualDrawerOffset > self.maxVisualDrawerOffset) {
        self.menuViewToSwipeViewLeftConstraint.active = NO;
        self.maxMenuViewToSwipeViewLeftConstraint.active = YES;
    }
    else {
        self.menuViewToSwipeViewLeftConstraint.active = YES;
        self.maxMenuViewToSwipeViewLeftConstraint.active = NO;
    }
}

- (void)setDrawerOpen:(BOOL)open animated:(BOOL)animated
{
    if (open && self.visualDrawerOffset == self.drawerWidth) {
        return;
    }

    if (! open && self.visualDrawerOffset == 0) {
        return;
    }

    dispatch_block_t action = ^() {
        self.visualDrawerOffset = open ? self.drawerWidth : 0;
        [self checkAndUpdateMaxVisualDrawerOffsetConstraints:self.visualDrawerOffset];
        [self layoutIfNeeded];
    };

    if (animated) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.35f animations:^{
            action();
        }];
    }
    else {
        action();
    }
}

- (void)closeDrawer:(NSNotification *)note
{
    if (note.object != self && self.mutuallyExclusiveSwipeIdentifier != nil) {
        
        NSDictionary *userInfo = note.userInfo;
        NSString *IDToClose = userInfo[SwipeMenuCollectionCellIDToCloseKey];
        if ((IDToClose != nil && [IDToClose isEqualToString:self.mutuallyExclusiveSwipeIdentifier]) || IDToClose == nil) {
            [self setDrawerOpen:NO animated:YES];
        }
    }
}

- (void)sendCellWillOpenNotification
{
    if (self.mutuallyExclusiveSwipeIdentifier == nil) {
        return;
    }
    NSNotification *note = [[NSNotification alloc] initWithName:SwipeMenuCollectionCellCloseDrawerNotification
                                                         object:self
                                                       userInfo:@{SwipeMenuCollectionCellIDToCloseKey : self.mutuallyExclusiveSwipeIdentifier}];
    
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL result = YES;
    
    if (gestureRecognizer == self.revealDrawerGestureRecognizer) {
        
        CGPoint offset = [self.revealDrawerGestureRecognizer translationInView:self];
        if (self.swipeViewHorizontalConstraint.constant == 0 && offset.x < 0) {
            result = NO;
        }
        else {
            result = fabs(offset.x) > fabs(offset.y);
        }
    }
    return result;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.revealDrawerGestureRecognizer) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || ![otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end

@implementation SwipeMenuCollectionCell (DrawerOverrides)

- (void)drawerScrollingEndedWithOffset:(CGFloat)offset
{
    // Intentionally left empty. No need to call super on it
}

- (void)drawerScrollingStarts
{
    // Intentionally left empty. No need to call super on it
}

@end
