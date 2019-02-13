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
#import "SwipeMenuCollectionCell+Internal.h"
#import "UIView+RemoveAnimations.h"
#import "Wire-Swift.h"


NSString * const SwipeMenuCollectionCellCloseDrawerNotification = @"SwipeMenuCollectionCellCloseDrawerNotification";
NSString * const SwipeMenuCollectionCellIDToCloseKey = @"IDToClose";

@interface SwipeMenuCollectionCell () <UIGestureRecognizerDelegate>

@property (nonatomic) UIView *swipeView;
@property (nonatomic) UIView *menuView;

@property (nonatomic) CGFloat initialDrawerWidth;

@property (nonatomic) CGFloat initialDrawerOffset;
@property (nonatomic) CGPoint initialDragPoint;
@property (nonatomic) BOOL revealDrawerOverscrolled;
@property (nonatomic) BOOL revealAnimationPerforming;
@property (nonatomic) CGFloat scrollingFraction;
@property (nonatomic) CGFloat userInteractionHorizontalOffset;

@property (nonatomic) UIPanGestureRecognizer *revealDrawerGestureRecognizer;

@property (nonatomic) UIImpactFeedbackGenerator *openedFeedbackGenerator;

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
    /// When the swipeView is swiped and excesses this offset, the "3 dots" stays at left.
    self.maxVisualDrawerOffset = MaxVisualDrawerOffsetRevealDistance;
    
    self.swipeView = [[UIView alloc] init];
    self.swipeView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.swipeView];

    self.menuView = [[UIView alloc] init];
    self.menuView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.menuView];
    
    self.separatorLine = [[UIView alloc] init];
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
    
    if (nil != [UIImpactFeedbackGenerator class]) {
        self.openedFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    }
}

- (void)setSeparatorLineViewDisabled:(BOOL)separatorLineViewDisabled
{
    _separatorLineViewDisabled = separatorLineViewDisabled;
    self.separatorLine.hidden = separatorLineViewDisabled;
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

            [self.openedFeedbackGenerator prepare];
            
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
                    [self.openedFeedbackGenerator impactOccurred];
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
            
            [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.35f animations:^{
                self.scrollingFraction = self.userInteractionHorizontalOffset / self.bounds.size.width;
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
            
            [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.35f animations:^{
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

- (void)setDrawerOpen:(BOOL)open animated:(BOOL)animated
{
    if (open && self.visualDrawerOffset == self.drawerWidth) {
        return;
    }

    if (! open && self.visualDrawerOffset == 0) {
        return;
    }

    dispatch_block_t action = ^() {
        self.visualDrawerOffset = 0;
        [self layoutIfNeeded];
    };

    if (animated) {
        [UIView wr_animateWithEasing:WREasingFunctionEaseOutExpo duration:0.35f animations:^{
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
    // all other recognizers require this pan recognizer to fail
    return gestureRecognizer == self.revealDrawerGestureRecognizer;
}

// NOTE:
// In iOS 11, the force touch gesture recognizer used for peek & pop was blocking
// the pan gesture recognizer used for the swipeable cell. The fix to this problem
// however broke the correct behaviour for iOS 10 (namely, the pan gesture recognizer
// was now blocking the force touch recognizer). Although Apple documentation suggests
// getting the reference to the force recognizer and using delegate methods to create
// failure requirements, setting the delegate raised an exception (???). Here we
// simply apply the fix for iOS 11 and above.

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // for iOS version >= 11
    if ([[[UIDevice currentDevice] systemVersion] compare:@"11" options:NSNumericSearch] != NSOrderedAscending) {
        // pan recognizer should not require failure of any other recognizer
        return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    } else {
        return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || ![otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // iOS version >= 11
    if ([[[UIDevice currentDevice] systemVersion] compare:@"11" options:NSNumericSearch] != NSOrderedAscending) {
        // pan recognizer should not recognize simultaneously with any other recognizer
        return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
    } else {
        return YES;
    }
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
