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


#import "SplitViewController.h"
#import "SplitViewController+internal.h"
#import "Wire-Swift.h"

NSString *SplitLayoutObservableDidChangeToLayoutSizeNotification = @"SplitLayoutObservableDidChangeToLayoutSizeNotificationName";






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
- (void)pauseInteractiveTransition {}

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


@interface SplitViewController ()

@property (nonatomic) UIPanGestureRecognizer *horizontalPanner;

@property (nonatomic) UITraitCollection *futureTraitCollection;

@end

@implementation SplitViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];

    self.leftView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.leftView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.leftView];
    
    self.rightView = [[PlaceholderConversationView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.rightView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorBackground];
    [self.view addSubview:self.rightView];
    
    [self setupInitialConstraints];
    [self updateLayoutSizeForTraitCollection:self.traitCollection];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self updateForSize:size];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateLayoutSizeAndLeftViewVisibility];
    }];

}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.futureTraitCollection = newCollection;
    [self updateLayoutSizeForTraitCollection:newCollection];

    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [self updateActiveConstraints];
    
    [self updateLeftViewVisibility];
}

- (void)updateForSize:(CGSize)size
{
    if (nil != self.futureTraitCollection) {
        [self updateLayoutSizeForTraitCollection:self.futureTraitCollection];
    } else {
        [self updateLayoutSizeForTraitCollection:self.traitCollection];
    }
    
    [self updateConstraintsForSize:size];
    [self updateActiveConstraints];

    self.futureTraitCollection = nil;

    // update right view constraits after size changes
    [self updateRightAndLeftEdgeConstraints: self.openPercentage];
}

- (void)updateConstraintsForSize:(CGSize)size {
    [self updateConstraintsForSize:size willMoveToEmptyView:NO];
}

- (void)updateLayoutSizeAndLeftViewVisibility
{
    [self updateLayoutSizeForTraitCollection:self.traitCollection];
    [self updateLeftViewVisibility];
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

- (void)setInternalLeftViewController:(nullable UIViewController *)leftViewController {
    _leftViewController = leftViewController;
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController
{
    [self setLeftViewController:leftViewController animated:NO completion:nil];
}

- (void)setLeftViewController:(nullable UIViewController *)leftViewController animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    [self setLeftViewController:leftViewController animated:animated transition:SplitViewControllerTransitionDefault completion:completion];
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


- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerIsRevealed
{
    _leftViewControllerRevealed = leftViewControllerIsRevealed;
    [self updateLeftViewControllerVisibilityAnimated:YES completion:nil];
}

- (void)setLeftViewControllerRevealed:(BOOL)leftViewControllerRevealed animated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    _leftViewControllerRevealed = leftViewControllerRevealed;
    [self updateLeftViewControllerVisibilityAnimated:animated completion:completion];
}

- (void)setOpenPercentage:(CGFloat)percentage
{
    _openPercentage = percentage;
    [self updateRightAndLeftEdgeConstraints: percentage];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

//- (void)updateRightAndLeftEdgeConstraints:(CGFloat)percentage
//{
//    self.rightViewLeadingConstraint.constant = self.leftViewWidthConstraint.constant * percentage;
//    self.leftViewLeadingConstraint.constant = 64.0f * (1.0f - percentage);
//}

@end
