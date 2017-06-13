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

@import Classy;
@import WireExtensionComponents;
#import "Wire-Swift.h"


#import "ActionSheetController.h"
#import "ActionSheetTransition.h"
#import "ActionSheetContainerView.h"
#import "ActionSheetListView.h"
#import "ActionSheetAlertView.h"


@interface DefaultActionSheetTransitioningDelegate : NSObject<UIViewControllerTransitioningDelegate>

@end


@implementation DefaultActionSheetTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    NSAssert([presented isKindOfClass:[ActionSheetController class]], @"DefaultActionSheetTransitioningDelegate can only present a ActionSheetController");
    
    return [[ActionSheetTransition alloc] initWithActionSheetContainerView:(ActionSheetContainerView *)presented.view reverse:NO];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    NSAssert([dismissed isKindOfClass:[ActionSheetController class]], @"DefaultActionSheetTransitioningDelegate can only present a ActionSheetController");
    
    return [[ActionSheetTransition alloc] initWithActionSheetContainerView:(ActionSheetContainerView *)dismissed.view reverse:YES];
}

@end


@interface SheetAction ()

@property (nonatomic) NSString *title;
@property (nonatomic) ZetaIconType iconType;
@property (nonatomic) SheetActionStyle style;
@property (nonatomic, copy) void (^handler)(SheetAction *action);

- (instancetype)initWithTitle:(NSString *)title iconType:(ZetaIconType)iconType style:(SheetActionStyle)style handler:(void (^)(SheetAction *action))handler;

@end


@implementation SheetAction

+ (instancetype)actionWithTitle:(NSString *)title iconType:(ZetaIconType)iconType handler:(void (^)(SheetAction *action))handler
{
    return [[self.class alloc] initWithTitle:title iconType:iconType style:SheetActionStyleDefault handler:handler];
}

+ (instancetype)actionWithTitle:(NSString *)title iconType:(ZetaIconType)iconType style:(SheetActionStyle)style handler:(void (^)(SheetAction *))handler
{
    return [[self.class alloc] initWithTitle:title iconType:iconType style:style handler:handler];
}

- (instancetype)initWithTitle:(NSString *)title iconType:(ZetaIconType)iconType style:(SheetActionStyle)style handler:(void (^)(SheetAction *))handler
{
    self = [super init];
    
    if (self) {
        self.title = [title copy];
        self.iconType = iconType;
        self.style = style;
        self.handler = handler;
    }
    
    return self;
}

- (void)performAction:(id)sender
{
    if (self.handler != nil) {
        self.handler(self);
    }
}

@end



@interface ActionSheetController ()

@property (nonatomic) NSArray *actions;
@property (nonatomic) NSArray *checkBoxButtons;
@property (nonatomic) NSMutableArray *actionSheetControllers;
@property (nonatomic) DefaultActionSheetTransitioningDelegate *defaultTransitioningDelegate;
@property (nonatomic, readonly) ActionSheetControllerLayout layout;
@property (nonatomic, readonly) ActionSheetContainerView *actionSheetContainerView;
@property (nonatomic, readonly) UIView *sheetView;
@property (nonatomic, readonly) UIView *titleView;

@end

@implementation ActionSheetController

- (instancetype)initWithTitle:(NSString *)title layout:(ActionSheetControllerLayout)layout style:(ActionSheetControllerStyle)style
{
    return [self initWithTitle:title layout:layout style:style dismissStyle:ActionSheetControllerDismissStyleBackground];
}

- (instancetype)initWithTitle:(NSString *)title layout:(ActionSheetControllerLayout)layout style:(ActionSheetControllerStyle)style dismissStyle:(ActionSheetControllerDismissStyle)dismissStyle
{
    UILabel *titleLabel = [[UILabel alloc] initForAutoLayout];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    titleLabel.accessibilityIdentifier = @"dialog title";
    titleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.normal.font_spec_bold"];
    return [self initWithTitleView:titleLabel layout:layout style:style dismissStyle:dismissStyle];
}

- (instancetype)initWithTitleView:(UIView *)titleView
                           layout:(ActionSheetControllerLayout)layout
                            style:(ActionSheetControllerStyle)style
                     dismissStyle:(ActionSheetControllerDismissStyle)dismissStyle
{
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        self.actions = @[];
        self.checkBoxButtons = @[];
        self.actionSheetControllers = [NSMutableArray array];
        self.defaultTransitioningDelegate = [[DefaultActionSheetTransitioningDelegate alloc] init];
        self.transitioningDelegate = self.defaultTransitioningDelegate;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        _titleView = titleView;
        _layout = layout;
        _style = style;
        _dismissStyle = dismissStyle;
    }

    return self;
}

- (void)loadView
{
    self.view = [[ActionSheetContainerView alloc] initWithStyle:self.style == ActionSheetControllerStyleLight ? ActionSheetViewStyleLight : ActionSheetViewStyleDark];
}

- (ActionSheetContainerView *)actionSheetContainerView
{
    return (ActionSheetContainerView *)self.view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.actionSheetContainerView.topContainerView addSubview:self.titleView];
    [self.titleView autoPinEdgesToSuperviewEdges];

    self.actionSheetContainerView.sheetView = self.sheetView;

    if (self.dismissStyle == ActionSheetControllerDismissStyleBackground) {
        [self.actionSheetContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapped:)]];
    } else {
        [self addCloseButton];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] wr_updateStatusBarForCurrentControllerAnimated:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIView *)sheetView
{
    UIView *sheetView = nil;
    
    if (self.layout == ActionSheetControllerLayoutList) {
        sheetView = [[ActionSheetListView alloc] initWithActions:self.actions.reverseObjectEnumerator.allObjects];
    }
    else if (self.layout == ActionSheetControllerLayoutAlert) {
        ActionSheetAlertView *alertView = [[ActionSheetAlertView alloc] initWithActions:self.actions buttons:self.checkBoxButtons];
        alertView.titleLabel.text = self.messageTitle;
        alertView.messageLabel.text = self.message;
        alertView.imageView.image = self.iconImage;
        sheetView = alertView;
    }
    
    return sheetView;
}

- (void)addAction:(SheetAction *)action
{
    NSMutableArray *mutableActions = [NSMutableArray arrayWithArray:self.actions];
    [mutableActions addObject:action];
    self.actions = [mutableActions copy];
}

- (void)addCheckBoxButtonWithConfigurationHandler:(void (^)(CheckBoxButton *checkBoxButton))configurationHandler
{
    CheckBoxButton *checkBoxButton = [[CheckBoxButton alloc] init];
    
    configurationHandler(checkBoxButton);
    
    NSMutableArray *mutableIconButtons = [NSMutableArray arrayWithArray:self.checkBoxButtons];
    [mutableIconButtons addObject:checkBoxButton];
    self.checkBoxButtons = [mutableIconButtons copy];
}

- (void)addCloseButton
{
    IconButton *closeButton = [IconButton iconButtonCircular];
    closeButton.accessibilityIdentifier = @"closeButton";
    [closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:14.0f];
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:18.0f];
    [closeButton autoSetDimensionsToSize:(CGSize) {32, 32}];
}

- (void)pushActionSheetController:(ActionSheetController *)actionSheetControllerToPresent animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [self.actionSheetControllers addObject:actionSheetControllerToPresent];
    [self.actionSheetContainerView transitionFromSheetView:self.actionSheetContainerView.sheetView toSheetView:actionSheetControllerToPresent.sheetView completion:^(BOOL finished) {
        if (completion != nil) completion();
    }];
}

- (void)popActionSheetControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    if (self.actionSheetControllers.count == 0) {
        return;
    }
    
    [self.actionSheetControllers removeLastObject];
    
    ActionSheetController *actionSheetControllerToPresent = nil;
    if (self.actionSheetControllers.count > 0) {
        actionSheetControllerToPresent = [self.actionSheetControllers lastObject];
    } else {
        actionSheetControllerToPresent = self;
    }
    
    [self.actionSheetContainerView transitionFromSheetView:self.actionSheetContainerView.sheetView toSheetView:actionSheetControllerToPresent.sheetView completion:^(BOOL finished) {
        if (completion != nil) completion();
    }];
}

#pragma mark - Gesture Recognizers

- (void)dismissTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
