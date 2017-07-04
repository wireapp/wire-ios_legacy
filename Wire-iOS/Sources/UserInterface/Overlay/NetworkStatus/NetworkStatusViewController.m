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


#import "NetworkStatusViewController.h"

@import PureLayout;

// ui
#import "PassthroughTouchesView.h"

// helpers

#import "WAZUIMagicIOS.h"
#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

typedef NS_ENUM(NSInteger, StatusBarState) {
    StatusBarStateOk,
    StatusBarStateServerUnreachable
};

typedef NS_ENUM(NSInteger, NetworkAlertType) {
    NetworkAlertTypeOffline,
    NetworkAlertTypeLowQuality
};


static CGFloat expandedHeight, collapsedHeight;
static UIFont *font;
static UIColor *fontColor, *warningBackgroundColor;



@interface NetworkStatusViewController (Animations)

- (void)expandBarWithTimeout;
- (void)collapseBarWithCompletion:(dispatch_block_t)completion;

@end



@interface NetworkStatusViewController () <UIAlertViewDelegate>

@property (nonatomic, readonly) StatusBarState statusBarState;
@property (nonatomic, assign) StatusBarState pendingStatusBarState;

@property (nonatomic, assign) BOOL statusBarIsExpanded;

@property (nonatomic, assign) BOOL monitoringEnabled;

/// The container view that is actually doing the presentation
@property (nonatomic, strong) UIView *animatedContainer;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSLayoutConstraint *animatedContainerHeight;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) NSTimer *collapseTimer;
@property (nonatomic, strong) id serverConnectionObserverToken;

@end


@interface NetworkStatusViewController (ServerConnection) <ServerConnectionObserver>

@end



@implementation NetworkStatusViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        _statusBarState = StatusBarStateOk;
        self.monitoringEnabled = NO;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor clearColor];
    
    // set up the container that will be animating
    
    self.statusLabel = [[UILabel alloc] initForAutoLayout];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    
    self.animatedContainer = [[UIView alloc] initForAutoLayout];
    [self.view addSubview:self.animatedContainer];
    
    [self.animatedContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    self.animatedContainerHeight = [self.animatedContainer autoSetDimension:ALDimensionHeight toSize:0];
    
    [self.animatedContainer addSubview:self.statusLabel];
    
    [self.statusLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    expandedHeight = [WAZUIMagic floatForIdentifier:@"system_status_bar.expanded_height"];
    collapsedHeight = [WAZUIMagic floatForIdentifier:@"system_status_bar.collapsed_height"];
    font = [UIFont fontWithMagicIdentifier:@"system_status_bar.warning_font"];
    fontColor = [UIColor colorWithMagicIdentifier:@"system_status_bar.warning_font_color"];
    warningBackgroundColor = [UIColor colorWithMagicIdentifier:@"system_status_bar.warning_background_color"];
    
    self.statusLabel.font = font;
    self.statusLabel.textColor = fontColor;
    self.statusLabel.backgroundColor = [UIColor clearColor];

    [self addTapGestureRecognizer];
    
    self.serverConnectionObserverToken = [SessionManager.shared.serverConnection addObserver:self];
    
    // Set the view hidden to disable receiving touches. It will be eventually set to NO by a reachability change.
    self.view.hidden = YES;

    __weak NetworkStatusViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) ([WAZUIMagic floatForIdentifier:@"system_status_bar.startup_delay"] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.monitoringEnabled = YES;
        [self updateState];
    });
}

- (void)addTapGestureRecognizer
{
    if (! self.tapGestureRecognizer) {
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnBackground:)];
        [self.animatedContainer addGestureRecognizer:self.tapGestureRecognizer];
    }
}

- (void)dealloc
{
    [SessionManager.shared.serverConnection removeObserver:self.serverConnectionObserverToken];
}

- (void)tappedOnBackground:(UIGestureRecognizer *)sender
{
    if (self.animatedContainerHeight.constant == expandedHeight) {
        // if tapping on the bar, pick the type of alert to show, based on server reachability
        [self showAlertWithType:NetworkAlertTypeOffline];
    }
    else {
        [self expandBarWithTimeout];
    }
}

- (void)updateState
{
    BOOL isOffline = SessionManager.shared.serverConnection.isOffline;
    [self enqueueStatusBarStateChange:isOffline ? StatusBarStateServerUnreachable : StatusBarStateOk];
}

- (void)flashNetworkStatusIfNecessaryAndShowAlert:(BOOL)showAlert
{
    if (self.statusBarState == StatusBarStateServerUnreachable) {
        [self expandBarWithTimeout];
        
        if (showAlert) {
            [self showAlertWithType:NetworkAlertTypeOffline];
        }
    }
}

- (void)showAlertWithType:(NetworkAlertType)alertType
{
    NSString *title = NSLocalizedString(@"system_status_bar.no_internet.title", @"");
    NSString *explanation = NSLocalizedString(@"system_status_bar.no_internet.explanation", @"");
    
    if (alertType == NetworkAlertTypeLowQuality) {
        title = NSLocalizedString(@"system_status_bar.poor_connectivity.title", @"");
        explanation = NSLocalizedString(@"system_status_bar.poor_connectivity.explanation", @"");
    }
    
    NSString *acknowledge = NSLocalizedString(@"general.confirm", @"OK");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:explanation
                                                   delegate:self
                                          cancelButtonTitle:acknowledge
                                          otherButtonTitles:nil];
    alert.delegate = self;
    [alert show];
}

- (void)enqueueStatusBarStateChange:(StatusBarState)state
{
    if (! self.monitoringEnabled) {
        return;
    }

    // represented state is already correct, nothing to do
    if ((state == self.statusBarState) && self.pendingStatusBarState == state) {
        return;
    }
    
    self.pendingStatusBarState = state;

    [self dequeueAndRunStatusBarChange];
}

- (void)dequeueAndRunStatusBarChange
{
    if (self.pendingStatusBarState == self.statusBarState) {
        return;
    }

    _statusBarState = self.pendingStatusBarState;

    if (self.statusBarState == StatusBarStateOk) {
        
        if (self.statusBarIsExpanded) {
            
        }
        self.animatedContainerHeight.constant = 0;
        [self.view setNeedsUpdateConstraints];
        
        [self collapseBarWithCompletion:^{
            if (self.pendingStatusBarState != self.statusBarState) {
                [self dequeueAndRunStatusBarChange];
            } else {
                self.view.hidden = YES;
            }
        }];
    } else if (self.statusBarState == StatusBarStateServerUnreachable) {
        self.view.hidden = NO;
        [self expandBarWithTimeout];
    }
}

- (NSString *)titleForConnectivity
{
    return NSLocalizedString(@"system_status_bar.no_internet.title", @"");
}

- (NSString *)explanationForConnectivity
{
    return NSLocalizedString(@"system_status_bar.no_internet.explanation", @"");
}

@end



@implementation NetworkStatusViewController (ServerConnection)

- (void)serverConnectionDidChange:(id<ServerConnection>)serverConnection
{
    [self updateState];
}

@end



@implementation NetworkStatusViewController (Animations)

- (void)updateCollapseTimer
{
    if (self.collapseTimer != nil) {
        [self.collapseTimer invalidate];
    }
    NSTimeInterval timeout = [WAZUIMagic floatForIdentifier:@"system_status_bar.collapse_animation.delay_after_expand"];
    self.collapseTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(collapseBarAfterTimeout) userInfo:nil repeats:NO];
    self.collapseTimer.tolerance = 0.2;
}

- (void)expandBarWithTimeout
{
    
    if (! self.statusBarIsExpanded) {
        self.statusBarIsExpanded = YES;
        self.statusLabel.text = [[self titleForConnectivity] uppercasedWithCurrentLocale];
        self.statusLabel.alpha = 0;
        self.animatedContainer.alpha = 0;
        self.animatedContainer.backgroundColor = warningBackgroundColor;
        self.animatedContainerHeight.constant = expandedHeight;
        
        [UIView animateWithAnimationIdentifier:@"system_status_bar.expand_animation" animations:^{
            [self.view layoutIfNeeded];
            self.animatedContainer.alpha = 1;
            self.statusLabel.alpha = 1;
        } options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState completion:^(BOOL finished) {
            [self updateCollapseTimer];
        }];
    }
    else {
        [self updateCollapseTimer];
    }
}

- (void)collapseBarAfterTimeout
{
    [self collapseBarWithCompletion:^{
        if (self.pendingStatusBarState != self.statusBarState) {
            [self dequeueAndRunStatusBarChange];
        }
    }];
}

- (void)collapseBarWithCompletion:(dispatch_block_t)completion
{
    if (self.statusBarIsExpanded) {
        self.statusBarIsExpanded = NO;
        [self.collapseTimer invalidate];
        self.collapseTimer = nil;
        self.animatedContainerHeight.constant = collapsedHeight;
        [self.view setNeedsUpdateConstraints];

        [UIView animateWithAnimationIdentifier:@"system_status_bar.collapse_animation" animations:^{
            
            self.statusLabel.alpha = 0;
            [self.view layoutIfNeeded];
            
        } options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }
    else {
        if (self.pendingStatusBarState != self.statusBarState) {
            [self dequeueAndRunStatusBarChange];
        }
    }
}

@end

