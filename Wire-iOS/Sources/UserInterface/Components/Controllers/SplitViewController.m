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


@import PureLayout;


#import "SplitViewController.h"
#import "CrossfadeTransition.h"
#import "SwizzleTransition.h"
#import "VerticalTransition.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "UIColor+WR_ColorScheme.h"
#import "Constants.h"

#import "Wire-Swift.h"


typedef NS_ENUM(NSInteger, SplitViewControllerTransition) {
    SplitViewControllerTransitionDefault,
    SplitViewControllerTransitionPresent,
    SplitViewControllerTransitionDismiss
};

NSString *SplitLayoutObservableDidChangeToLayoutSizeNotification = @"SplitLayoutObservableDidChangeToLayoutSizeNotificationName";


@interface SplitViewControllerTransitionContext : NSObject <UIViewControllerContextTransitioning>

@property (nonatomic, copy) void (^completionBlock)(BOOL didComplete);
@property (nonatomic, getter=isAnimated) BOOL animated;
@property (nonatomic, getter=isInteractive) BOOL interactive;

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController containerView:(UIView *)containerView;

@end



@interface SplitViewControllerTransitionContext ()

@property (nonatomic) NSDictionary *viewControllers;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UIModalPresentationStyle presentationStyle;

@end



@implementation SplitViewControllerTransitionContext

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController containerView:(UIView *)containerView
{
    self = [super init];
    
    if (self) {
        self.presentationStyle = UIModalPresentationCustom;
        self.containerView = containerView;
        
        NSMutableDictionary *viewControllers = [NSMutableDictionary dictionary];
        
        if (fromViewController != nil) {
            [viewControllers setObject:fromViewController forKey:UITransitionContextFromViewControllerKey];
        }
        
        if (toViewController != nil) {
            [viewControllers setObject:toViewController forKey:UITransitionContextToViewControllerKey];
        }
        
        self.viewControllers = [viewControllers copy];
    }
    
    return self;
}

- (CGRect)initialFrameForViewController:(UIViewController *)viewController {
    return self.containerView.bounds;
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController {
    return self.containerView.bounds;
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
    return self.viewControllers[key];
}

- (UIView *)viewForKey:(NSString *)key
{
    if ([key isEqualToString:UITransitionContextToViewKey]) {
        return [self.viewControllers[UITransitionContextToViewControllerKey] view];
    }
    
    if ([key isEqualToString:UITransitionContextFromViewKey]) {
        return [self.viewControllers[UITransitionContextFromViewControllerKey] view];
    }
    
    return nil;
}

- (void)completeTransition:(BOOL)didComplete {
    if (self.completionBlock) {
        self.completionBlock (didComplete);
    }
}

- (BOOL)transitionWasCancelled { return NO; } // Our non-interactive transition can't be cancelled (it could be interrupted, though)

// Supress warnings by implementing empty interaction methods for the remainder of the protocol:

- (CGAffineTransform)targetTransform { return CGAffineTransformIdentity; }
- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {}
- (void)cancelInteractiveTransition {}

@end


@implementation UIViewController (SplitViewController)

- (SplitViewController *)wr_splitViewController
{
    UIViewController *possibleSplit = self;
    
    do {
        if ([possibleSplit isKindOfClass:[SplitViewController class]]) {
            return (SplitViewController *)possibleSplit;
        }
        possibleSplit = possibleSplit.parentViewController;
    }
    while(possibleSplit != nil);
    
    return nil;
}

@end


@interface SplitViewController () <UIGestureRecognizerDelegate>

@property (nonatomic) UIView *leftView;
@property (nonatomic) UIView *rightView;

@property (nonatomic) NSLayoutConstraint *leftViewOffsetConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewOffsetConstraint;

@property (nonatomic) NSLayoutConstraint *leftViewWidthConstraint;
@property (nonatomic) NSLayoutConstraint *rightViewWidthConstraint;

@property (nonatomic) NSLayoutConstraint *sideBySideConstraint;
@property (nonatomic) NSLayoutConstraint *pinLeftViewOffsetConstraint;

@property (nonatomic) UIPanGestureRecognizer *horizontalPanner;

@property (nonatomic) CGFloat openPercentage;
@property (nonatomic) UITraitCollection *futureTraitCollection;

@property (nonatomic) SplitViewControllerLayoutSize layoutSize;

@end

@implementation SplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];

    self.leftView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.leftView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.leftView];
    
    self.rightView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.rightView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBackground];
    [self.view addSubview:self.rightView];
    
    [self setupInitialConstraints];
    [self updateLayoutSizeForTraitCollection:self.traitCollection size:self.view.bounds.size];
    [self updateConstraintsForSize:self.view.bounds.size];
    [self updateActiveConstraints];
    
    _leftViewControllerRevealed = YES;
    self.openPercentage = 1;
    self.horizontalPanner = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onHorizontalPan:)];
    self.horizontalPanner.delegate = self;
    [self.view addGestureRecognizer:self.horizontalPanner];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self updateForSize:self.view.bounds.size];
}

- (void)setupInitialConstraints
{
    [self.leftView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.leftView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [self.rightView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.rightView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    
    [NSLayoutConstraint autoSetPriority:UILayoutPriorityDefaultHigh forConstraints:^{
        self.leftViewOffsetConstraint = [self.leftView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        self.rightViewOffsetConstraint = [self.rightView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    }];
    
    self.leftViewWidthConstraint = [self.leftView autoSetDimension:ALDimensionWidth toSize:0];
    self.rightViewWidthConstraint = [self.rightView autoSetDimension:ALDimensionWidth toSize:0];
    
    self.pinLeftViewOffsetConstraint = [self.leftView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    self.sideBySideConstraint = [self.rightView autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.leftView];
    self.sideBySideConstraint.active = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self updateForSize:size];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.futureTraitCollection = newCollection;
    [self updateLayoutSizeForTraitCollection:newCollection size:self.view.bounds.size];

    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [self updateActiveConstraints];
    
    [self updateLeftViewVisibility];
}

- (void)updateForSize:(CGSize)size
{
    if (nil != self.futureTraitCollection) {
        [self updateLayoutSizeForTraitCollection:self.futureTraitCollection size:size];
    } else {
        [self updateLayoutSizeForTraitCollection:self.traitCollection size:size];
    }
    
    [self updateConstraintsForSize:size];
    [self updateActiveConstraints];
    [self updateLeftViewVisibility];

    self.futureTraitCollection = nil;
}

- (void)updateLayoutSizeForTraitCollection:(UITraitCollection *)traitCollection size:(CGSize)size
{
    if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.layoutSize = SplitViewControllerLayoutSizeCompact;
    }
    else if (IS_IPAD_PORTRAIT_LAYOUT) {
        self.layoutSize = SplitViewControllerLayoutSizeRegularPortrait;
    }
    else {
        self.layoutSize = SplitViewControllerLayoutSizeRegularLandscape;
    }
}

- (void)updateConstraintsForSize:(CGSize)size
{
    if (self.layoutSize == SplitViewControllerLayoutSizeCompact) {
        self.leftViewWidthConstraint.constant = size.width;
        self.rightViewWidthConstraint.constant = size.width;
    }
    else if (self.layoutSize == SplitViewControllerLayoutSizeRegularPortrait) {
        self.leftViewWidthConstraint.constant = MIN(CGRound(size.width * 0.43), 336);
        self.rightViewWidthConstraint.constant = size.width;
    }
    else {
        self.leftViewWidthConstraint.constant = MIN(CGRound(size.width * 0.43), 336);
        self.rightViewWidthConstraint.constant = size.width - self.leftViewWidthConstraint.constant;
    }
}

- (void)updateLeftViewVisibility
{
    switch(self.layoutSize) {
        case SplitViewControllerLayoutSizeCompact: // fallthrough
        case SplitViewControllerLayoutSizeRegularPortrait:
            self.leftView.hidden = self.openPercentage == 0;
            break;
        case SplitViewControllerLayoutSizeRegularLandscape:
            self.leftView.hidden = NO;
            break;
    }
}

- (CGFloat)leftViewControllerWidth
{
    return self.leftViewWidthConstraint.constant;
}

- (void)setLayoutSize:(SplitViewControllerLayoutSize)layoutSize
{
    if (_layoutSize != layoutSize) {
        _layoutSize = layoutSize;
        [[NSNotificationCenter defaultCenter] postNotificationName:SplitLayoutObservableDidChangeToLayoutSizeNotification object:self];
    }
}

- (void)updateActiveConstraints
{
    [[self constraintsInactiveForCurrentLayout] autoRemoveConstraints];
    [[self constraintsActiveForCurrentLayout] autoInstallConstraints];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.openPercentage > 0) {
        return self.leftViewController.preferredStatusBarStyle;
    }
    else {
        return self.rightViewController.preferredStatusBarStyle;
    }
}

- (BOOL)prefersStatusBarHidden
{
    if (self.openPercentage > 0) {
        return self.leftViewController.prefersStatusBarHidden;
    }
    else {
        return self.rightViewController.prefersStatusBarHidden;
    }
}

- (BOOL)shouldDisplayNotificationFrom:(Account *)account
{
    if (account.isActive && self.layoutSize == SplitViewControllerLayoutSizeRegularLandscape) {
        return NO; // in landscape on big a screen you always see the conversation list
    }
    
    if (self.openPercentage > 0) {
        return [self.leftViewController shouldDisplayNotificationFrom:account];
    }
    else {
        return [self.rightViewController shouldDisplayNotificationFrom:account];
    }
}

- (NSArray *)constraintsActiveForCurrentLayout
{
    NSMutableSet *constraints = [NSMutableSet set];
    
    if (self.layoutSize == SplitViewControllerLayoutSizeRegularLandscape) {
        [constraints addObjectsFromArray:@[self.pinLeftViewOffsetConstraint, self.sideBySideConstraint]];
    }
    
    [constraints addObjectsFromArray:@[self.leftViewWidthConstraint]];
    
    return [constraints allObjects];
}

- (NSArray *)constraintsInactiveForCurrentLayout
{
    NSMutableSet *constraints = [NSMutableSet set];
    
    if (self.layoutSize != SplitViewControllerLayoutSizeRegularLandscape) {
        [constraints addObjectsFromArray:@[self.pinLeftViewOffsetConstraint, self.sideBySideConstraint]];
    }
        
    return [constraints allObjects];
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController
{
    [self setLeftViewController:leftViewController animated:NO completion:nil];
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    [self setLeftViewController:leftViewController animated:animated transition:SplitViewControllerTransitionDefault completion:completion];
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController animated:(BOOL)animated transition:(SplitViewControllerTransition)transition completion:(nullable dispatch_block_t)completion
{
    if (self.leftViewController == leftViewController) {
        if(completion != nil) {
            completion();
        }
        return;
    }
    
    UIViewController *removedViewController = self.leftViewController;
    
    id<UIViewControllerAnimatedTransitioning> animator = nil;
    
    if (removedViewController == nil || leftViewController == nil) {
        animator = [[CrossfadeTransition alloc] init];
    } else if (transition == SplitViewControllerTransitionPresent) {
        animator = [[VerticalTransition alloc] initWithOffset:88];
    } else if (transition == SplitViewControllerTransitionDismiss) {
        animator = [[VerticalTransition alloc] initWithOffset:-88];
    } else {
        animator = [[CrossfadeTransition alloc] init];
    }
    
    BOOL transitionDidStart =
    [self transitionFromViewController:removedViewController
                      toViewController:leftViewController
                         containerView:self.leftView
                              animator:animator
                              animated:animated
                            completion:completion];
    
    if (transitionDidStart) {
        _leftViewController = leftViewController;
    }
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController
{
    [self setRightViewController:rightViewController animated:NO completion:nil];
}

- (void)setRightViewController:(nullable UIViewController *)rightViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    if (self.rightViewController == rightViewController) {
        return;
    }
    
    // To determine if self.rightViewController.presentedViewController is actually presented over it, or is it
    // presented over one of it's parents.
    if (self.rightViewController.presentedViewController.presentingViewController == self.rightViewController) {
        [self.rightViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    UIViewController *removedViewController = self.rightViewController;
    
    BOOL transitionDidStart =
    [self transitionFromViewController:removedViewController
                      toViewController:rightViewController
                         containerView:self.rightView
                              animator:[self animatorForRightView]
                              animated:animated
                            completion:completion];
    
    if (transitionDidStart) {
        _rightViewController = rightViewController;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animatorForRightView
{
    if (self.layoutSize == SplitViewControllerLayoutSizeCompact && self.leftViewControllerRevealed) {
        // Right view is not visible so we should not animate.
        return [[CrossfadeTransition alloc] initWithDuration:0];
    }
    else if (self.layoutSize == SplitViewControllerLayoutSizeRegularLandscape) {
        return [[SwizzleTransition alloc] init];
    }
    else {
        return [[CrossfadeTransition alloc] init];
    }
}

- (BOOL)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                       containerView:(UIView *)containerView
                            animator:(id<UIViewControllerAnimatedTransitioning>)animator
                            animated:(BOOL)animated
                          completion:(nullable dispatch_block_t)completion
{
    if ([self.childViewControllers containsObject:toViewController]) {
        return NO; // Return if transition is done or already in progress
    }
    
    [fromViewController willMoveToParentViewController:nil];
    
    if (toViewController != nil) {
        toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:toViewController];
    }
    
    SplitViewControllerTransitionContext *transitionContext = [[SplitViewControllerTransitionContext alloc] initWithFromViewController:fromViewController toViewController:toViewController containerView:containerView];
    
    transitionContext.interactive = NO;
    transitionContext.animated = animated;
    transitionContext.completionBlock = ^(BOOL didComplete) {
        [fromViewController.view removeFromSuperview];
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
        if (completion != nil) completion();
    };
    
    [animator animateTransition:transitionContext];
    
    return YES;
}

- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerIsRevealed
{
    [self setLeftViewControllerRevealed:leftViewControllerIsRevealed animated:YES completion:nil];
}

- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerRevealed animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    if (animated) {
        [self.view layoutIfNeeded];
    }
    
    self.leftView.hidden = NO;
    
    _leftViewControllerRevealed = leftViewControllerRevealed;
    self.openPercentage = leftViewControllerRevealed ? 1 : 0;
    
    if (self.layoutSize != SplitViewControllerLayoutSizeRegularLandscape) {
        [self.leftViewController beginAppearanceTransition:leftViewControllerRevealed animated:animated];
        [self.rightViewController beginAppearanceTransition:! leftViewControllerRevealed animated:animated];
    }
    
    if (animated) {
        if (leftViewControllerRevealed) {
            [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:NO];
        }
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo duration:0.55f animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (completion != nil) completion();
            
            if (self.layoutSize != SplitViewControllerLayoutSizeRegularLandscape) {
                [self.leftViewController endAppearanceTransition];
                [self.rightViewController endAppearanceTransition];
            }
            
            if (self.openPercentage == 0 && self.layoutSize != SplitViewControllerLayoutSizeRegularLandscape) {
                self.leftView.hidden = YES;
            }
        }];
    }
    else {
        [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:NO];
    }
}

- (void)setOpenPercentage:(CGFloat)percentage
{
    _openPercentage = percentage;
    self.rightViewOffsetConstraint.constant = self.leftViewWidthConstraint.constant * percentage;
    self.leftViewOffsetConstraint.constant = 64.0f * (1.0f - percentage);
}

#pragma mark - Gesture Recognizers

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.layoutSize == SplitViewControllerLayoutSizeRegularLandscape || ! [self.delegate splitViewControllerShouldMoveLeftViewController:self]) {
        return NO;
    }
    
    if (self.leftViewControllerRevealed && ! IS_IPAD_FULLSCREEN) {
        return NO;
    }
    
    return YES;
}

- (void)onHorizontalPan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (self.layoutSize == SplitViewControllerLayoutSizeRegularLandscape || ! [self.delegate splitViewControllerShouldMoveLeftViewController:self]) {
        return;
    }
    
    if (self.leftViewControllerRevealed && ! IS_IPAD_FULLSCREEN) {
        return;
    }
    
    CGPoint offset = [gestureRecognizer translationInView:self.view];
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self.leftViewController beginAppearanceTransition:! self.leftViewControllerRevealed animated:YES];
            [self.rightViewController beginAppearanceTransition:self.leftViewControllerRevealed animated:YES];
            self.leftView.hidden = NO;
            break;
            
        case UIGestureRecognizerStateChanged:
            
            if (self.leftViewControllerRevealed) {
                if (offset.x > 0) {
                    offset.x = 0;
                }
                if (CGAbs(offset.x) > self.leftViewController.view.bounds.size.width) {
                    offset.x = - self.self.leftViewController.view.bounds.size.width;
                }
                self.openPercentage = 1.0f - CGAbs(offset.x) / self.leftViewController.view.bounds.size.width;
            }
            else {
                if (offset.x < 0) {
                    offset.x = 0;
                }
                if (CGAbs(offset.x) > self.leftViewController.view.bounds.size.width) {
                    offset.x = self.leftViewController.view.bounds.size.width;
                }
                self.openPercentage = CGAbs(offset.x) / self.leftViewController.view.bounds.size.width;
                [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
            }
            [self.view layoutIfNeeded];
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            BOOL isRevealed = self.openPercentage > 0.5f;
            BOOL didCompleteTransition = isRevealed != self.leftViewControllerRevealed;
            
            @weakify(self);
            [self setLeftViewControllerRevealed:isRevealed animated:YES completion:^{
                
                @strongify(self);
                if (didCompleteTransition) {
                    [self.leftViewController endAppearanceTransition];
                    [self.rightViewController endAppearanceTransition];
                }
            }];
        }
            break;
            
        default:
            break;
    }
}

@end
