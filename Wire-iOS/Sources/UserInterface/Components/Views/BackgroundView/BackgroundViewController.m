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
#import <PureLayout/PureLayout.h>

@interface BackgroundViewController ()

@property (nonatomic) id<ZMBareUser> user;

@property (nonatomic) UIColor *filterColor;

@property (nonatomic) UserBackgroundView *backgroundView;
@property (nonatomic) NSLayoutConstraint *backgroundViewFullScreenConstraint;
@property (nonatomic) NSLayoutConstraint *backgroundViewSidebarConstraint;
@property (nonatomic) UIVisualEffectView *blurEffectView;

@property (nonatomic) AccentColorChangeHandler *accentColorHandler;

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
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorSchemeControllerDidApplyChanges:) name:ColorSchemeControllerDidApplyColorSchemeChangeNotification object:nil];
    
    [self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    
    self.backgroundViewFullScreenConstraint = [self.backgroundView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0.0f];

    CGFloat sidebarWidth = IS_IPAD ? [WAZUIMagic cgFloatForIdentifier:@"framework.sidebar_width"] : [UIScreen mainScreen].bounds.size.width;
    self.backgroundViewSidebarConstraint = [self.backgroundView autoSetDimension:ALDimensionWidth toSize:sidebarWidth];
    [self updateBackgroundViewLayout];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.blurEffectView];
    
    [self.blurEffectView autoPinEdgesToSuperviewEdges];
}

- (void)updateBackgroundViewLayout
{
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.backgroundViewFullScreenConstraint.active = NO;
        self.backgroundViewSidebarConstraint.active = YES;
    }
    else {
        self.backgroundViewSidebarConstraint.active = NO;
        self.backgroundViewFullScreenConstraint.active = YES;
    }
}

- (void)setFilterColor:(UIColor *)filterColor
{
    _filterColor = filterColor;
    self.backgroundView.filterColor = self.filterColor;
}

- (void)setUser:(id<ZMBareUser>)user animated:(BOOL)animated
{
    _user = user;
    
    [self.backgroundView setUser:user animated:animated];
}

#pragma mark - ColorSchemeControllerDidApplyChangesNotification

- (void)colorSchemeControllerDidApplyChanges:(NSNotification *)notification
{
    [self.backgroundView updateAppearanceAnimated:YES];
}

@end
