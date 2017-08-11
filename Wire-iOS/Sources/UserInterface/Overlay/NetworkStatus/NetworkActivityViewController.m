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


#import "NetworkActivityViewController.h"
#import "UIColor+WAZExtensions.h"
@import WireExtensionComponents;
#import "WAZUIMagicIOS.h"

#import "GapLayer.h"
#import "ZMUserSession+iOS.h"
#import "PassthroughTouchesView.h"
#import "AccentColorChangeHandler.h"
#import "WireSyncEngine+iOS.h"
#import "GapLoadingBar.h"


@import QuartzCore;

static CGFloat const MinBarLoadingTime = 1.0;
static CGFloat const MinDelayBeforeDisplay = 1.5;



@interface NetworkActivityViewController () <ZMNetworkAvailabilityObserver>

@property (nonatomic, strong) id accentColorChangeObserver;

@property (nonatomic) CGFloat activityViewHeight;
@property (nonatomic) CGFloat activityGapSize;
@property (nonatomic) CGFloat activityAnimationDuration;

@property (nonatomic, strong) GapLoadingBar *loadingBar;
@property (nonatomic, strong) NSDate *loadingBeganDate;

@property (nonatomic, strong) AccentColorChangeHandler *accentColorChangeHandler;


@property (nonatomic, strong) NSTimer *shouldDisplayTimer;
@property (nonatomic, strong) NSTimer *stopDisplayTimer;

@end


@implementation NetworkActivityViewController


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ZMNetworkAvailabilityChangeNotification removeNetworkAvailabilityObserver:self];
}


- (void)loadView
{
    self.view = [[PassthroughTouchesView alloc] init];
    self.view.clipsToBounds = YES;

    
    self.loadingBar = [GapLoadingBar barWithDefaultGapSizeAndAnimationDuration];
    self.loadingBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.loadingBar.accessibilityIdentifier = @"LoadBar";
    [self.view addSubview:self.loadingBar];
    
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.loadingBar addConstraintsHorizontallyFittingToView:self.view];
    [self.loadingBar addConstraintForTopMargin:0 relativeToView:self.view];
    
    CGFloat barHeight = [WAZUIMagic cgFloatForIdentifier:@"system_status_bar.collapsed_height"];
    [self.loadingBar addConstraintForHeight:barHeight];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.loadingBar.backgroundColor = [UIColor accentColor];

    @weakify(self);

    self.accentColorChangeHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, id object) {

        @strongify(self);
        self.loadingBar.backgroundColor = newColor;
    }];

    self.isLoading = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [ZMNetworkAvailabilityChangeNotification addNetworkAvailabilityObserver:self userSession:[ZMUserSession sharedSession]];
}

- (void)setIsLoadingMessages:(BOOL)isLoadingMessages
{
    _isLoadingMessages = isLoadingMessages;
    [self refreshShowOrHideLoadingBarWithNetworkState:[ZMUserSession sharedSession].networkState];
}

- (void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading == isLoading) {
        return;
    }

    _isLoading = isLoading;

    if (self.isLoading) {
        self.view.hidden = NO;
        self.loadingBar.animating = YES;
        self.loadingBeganDate = [NSDate date];
        
    }
    else {
        self.view.hidden = YES;
        self.loadingBar.animating = NO;
        self.loadingBeganDate = nil;
    }
}

- (void)didChangeAvailability:(ZMNetworkAvailabilityChangeNotification *)note
{
    [self refreshShowOrHideLoadingBarWithNetworkState:note.networkState];
}

- (void)refreshShowOrHideLoadingBarWithNetworkState:(ZMNetworkState)networkState
{
    [[ZMUserSession sharedSession] checkIfLoggedInWithCallback:^(BOOL isLoggedIn) {
        if ( !isLoggedIn || [ZMConversationList conversationsInUserSession:[ZMUserSession sharedSession]].count == 0) {
            self.isLoading = NO;
            return;
        }
        
        if ([self shouldShowLoadingBarWithNetworkStatusState:networkState]) {
            
            if (self.stopDisplayTimer.isValid){
                
                [self.stopDisplayTimer invalidate];
                self.stopDisplayTimer = nil;
                return;
            }
            
            self.shouldDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:MinDelayBeforeDisplay target:self selector:@selector(showLoadingBar:) userInfo:nil repeats:NO];
            self.shouldDisplayTimer.tolerance = 0.5;
            
        }
        else {
            
            NSTimeInterval elapsedLoadingTime = fabs([self.loadingBeganDate timeIntervalSinceNow]);
            
            if (elapsedLoadingTime > MinBarLoadingTime || self.loadingBeganDate == nil) {
                
                self.isLoading = NO;
            }
            else {
                
                NSTimeInterval remainingTime = MinBarLoadingTime - elapsedLoadingTime;
                
                self.stopDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:remainingTime target:self selector:@selector(hideLoadingBar:) userInfo:nil repeats:NO];
                self.stopDisplayTimer.tolerance = 0.5;
            }
            
        }
    }];
}

- (void)showLoadingBar:(NSTimer *)timer
{
    if ([self shouldShowLoadingBarWithNetworkStatusState:[ZMUserSession sharedSession].networkState]) {
        
        self.isLoading = YES;
    }
    
    [self.shouldDisplayTimer invalidate];
    self.shouldDisplayTimer = nil;
}

- (void)hideLoadingBar:(NSTimer *)timer
{
    if (![self shouldShowLoadingBarWithNetworkStatusState:[ZMUserSession sharedSession].networkState]) {
        self.isLoading = NO;
    }
    
    [self.stopDisplayTimer invalidate];
    self.stopDisplayTimer = nil;
}

- (BOOL)shouldShowLoadingBarWithNetworkStatusState:(ZMNetworkState)networkState;
{
    return networkState == ZMNetworkStateOnlineSynchronizing || self.isLoadingMessages;
}

- (void)applicationWillResignActive:(NSNotification *)note
{
    [self.shouldDisplayTimer invalidate];
    [self.stopDisplayTimer invalidate];
    
    self.isLoading = NO;
    
    self.shouldDisplayTimer = nil;
    self.stopDisplayTimer = nil;
}

@end
