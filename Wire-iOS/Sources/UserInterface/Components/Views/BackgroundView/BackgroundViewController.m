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


#import "BackgroundViewController.h"
#import "UserBackgroundView.h"
#import "zmessaging+iOS.h"
@import WireExtensionComponents;

#import "UIColor+WAZExtensions.h"
#import "UIView+Borders.h"
#import "Wire-Swift.h"
#import "WAZUIMagic.h"
#import "AccentColorChangeHandler.h"
#import "Constants.h"
#import "UIView+WR_ExtendedBlockAnimations.h"
#import "ColorSchemeController.h"

@interface BackgroundViewController (ConversationObserver) <ZMConversationObserver>

- (void)updateBackgroundForConversation;

@end

@interface BackgroundViewController ()

@property (nonatomic, strong) id<ZMBareUser> user;
@property (nonatomic, strong) id<ZMBareUser> overrideUser;

@property (nonatomic, strong) UIColor *filterColor;

@property (nonatomic, strong) UserBackgroundView *backgroundView;
@property (nonatomic, strong) NSLayoutConstraint *backgroundViewFullScreenConstraint;
@property (nonatomic, strong) NSLayoutConstraint *backgroundViewSidebarConstraint;

@property (nonatomic, strong) AccentColorChangeHandler *accentColorHandler;
@property (nonatomic) id conversationObserverToken;

@end



@implementation BackgroundViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *accentColor = [ZMUser selfUser].accentColor;
    if (! accentColor) {
        DDLogWarn(@"User has no accent color, picking ZMAccentColorSoftPink");
        accentColor = [UIColor colorForZMAccentColor:ZMAccentColorSoftPink];
    }
    
    self.backgroundView = [[UserBackgroundView alloc] initWithFilterColor:accentColor];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundView];

    @weakify(self);
    self.accentColorHandler = [AccentColorChangeHandler addObserver:self handlerBlock:^(UIColor *newColor, id object) {
        @strongify(self);
        self.filterColor = newColor;
        
        if (! self.overrideFilterColor) {
            self.backgroundView.filterColor = newColor;
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSchemeControllerDidApplyChanges:) name:ColorSchemeControllerDidApplyColorSchemeChangeNotification object:nil];
    
    [self.backgroundView addConstraintsVerticallyFittingToView:self.view];
    [self.backgroundView addConstraintForLeftMargin:0.0 relativeToView:self.view];
    
    self.backgroundViewFullScreenConstraint = [self.backgroundView addConstraintForRightMargin:0.0 relativeToView:self.view];

    CGFloat sidebarWidth = IS_IPAD ? [WAZUIMagic cgFloatForIdentifier:@"framework.sidebar_width"] : [UIScreen mainScreen].bounds.size.width;
    self.backgroundViewSidebarConstraint = [self.backgroundView addConstraintForWidth:sidebarWidth];
    [self updateBackgroundViewLayout];
}

- (void)updateBackgroundViewLayout
{
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad &&  ! self.forceFullScreen) {
        self.backgroundViewFullScreenConstraint.active = NO;
        self.backgroundViewSidebarConstraint.active = YES;
    }
    else {
        self.backgroundViewSidebarConstraint.active = NO;
        self.backgroundViewFullScreenConstraint.active = YES;
    }
}

- (void)setForceFullScreen:(BOOL)forceFullScreen
{
    [self setForceFullScreen:forceFullScreen animated:NO];
}

- (void)setForceFullScreen:(BOOL)forceFullScreen animated:(BOOL)animated
{
    _forceFullScreen = forceFullScreen;

    void (^animationBlock)() = ^() {
        [self updateBackgroundViewLayout];
    };
    
    if (animated) {
        [UIView wr_animateWithEasing:RBBEasingFunctionEaseOutExpo 
                            duration:[WAZUIMagic floatForIdentifier:@"background.animation_duration"] 
                          animations:^{
                              animationBlock(); 
                              [self updateViewConstraints];
                              [self.view layoutIfNeeded];
                          }];        
    }
    else {
        animationBlock();
    }
}

- (CGFloat)blurPercent
{
    return self.backgroundView.blurPercent;
}

- (void)setBlurPercent:(CGFloat)blurPercent
{
    self.backgroundView.blurPercent = blurPercent;
}

- (void)setBlurPercentAnimated:(CGFloat)blurPercent
{
    [self.backgroundView setBlurPercentAnimated:blurPercent];
}

- (BOOL)blurDisabled
{
    return self.backgroundView.blurDisabled;
}

- (void)setBlurDisabled:(BOOL)blurDisabled
{
    self.backgroundView.blurDisabled = blurDisabled;
}

- (void)setUser:(id<ZMBareUser>)user animated:(BOOL)animated
{
    _user = user;
    
    if (! self.overrideUser) {
        [self.backgroundView setUser:user animated:animated waitForBlur:YES];
    }
}

- (void)setOverrideUser:(id<ZMBareUser>)overrideUser disableColorFilter:(BOOL)disableColorFilter animated:(BOOL)animated;
{
    [self setOverrideUser:overrideUser disableColorFilter:(BOOL)disableColorFilter animated:animated completionBlock:nil];
}

- (void)setOverrideUser:(id<ZMBareUser>)overrideUser disableColorFilter:(BOOL)disableColorFilter animated:(BOOL)animated completionBlock:(dispatch_block_t)completionBlock;
{
    _overrideUser = overrideUser;
    
    if (overrideUser == nil) {
        [self unsetOverrideUserAnimated:animated];
    }
    else {
        [self.backgroundView setUser:overrideUser animated:animated waitForBlur:YES];
        self.backgroundView.filterDisabled = disableColorFilter;
    }
    
    if (completionBlock != nil) {
        completionBlock();
    }
}

- (void)unsetOverrideUserAnimated:(BOOL)animated
{
    self.overrideUser = nil;
    self.backgroundView.filterDisabled = NO;
    [self.backgroundView setUser:self.user animated:animated waitForBlur:YES];
}

- (void)setOverrideFilterColor:(UIColor *)overrideFilterColor;
{
    _overrideFilterColor = overrideFilterColor;
    
    if (overrideFilterColor != nil) {
        self.backgroundView.filterColor = overrideFilterColor;
    } else {
        self.backgroundView.filterColor = self.filterColor;
    }
}

- (void)setConversation:(ZMConversation *)conversation
{
    if (_conversation != conversation) {
        _conversation = conversation;
        if (_conversation != nil) {
            self.conversationObserverToken = [ConversationChangeInfo addObserver:self forConversation:self.conversation];
        }
        [self updateBackgroundForConversation];
    }
}

#pragma mark - ColorSchemeControllerDidApplyChangesNotification

- (void)colorSchemeControllerDidApplyChanges:(NSNotification *)notification
{
    [self.backgroundView updateAppearanceAnimated:YES];
}

@end

@implementation BackgroundViewController (ConversationObserver)

- (void)conversationDidChange:(ConversationChangeInfo *)change
{
    if (change.messagesChanged) {
        [self updateBackgroundForConversation];
    }
}

- (void)updateBackgroundForConversation
{
    ZMUser *user = self.conversation.lastMessageSender;
    if (user) {
        [self setUser:user animated:YES];
    }
}

@end
