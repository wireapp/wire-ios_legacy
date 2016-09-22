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


#import <PureLayout/PureLayout.h>


#import "ConnectionStatusHeader.h"
#import "zmessaging+iOS.h"
#import "UserImageView.h"
#import "UIFont+MagicAccess.h"
#import "UIColor+WR_ColorScheme.h"
#import "NSString+Wire.h"

@interface ConnectionStatusHeader () <ZMUserObserver>

@property (nonatomic) UserImageView *userImageView;
@property (nonatomic) UILabel *statusLabel;
@property (nonatomic) id<ZMUserObserverOpaqueToken> userObserverToken;
@property (nonatomic) ZMUser *user;

@end

@implementation ConnectionStatusHeader

- (instancetype)initWithUser:(ZMUser *)user
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _user = user;
        
        [self createViews];
        [self createConstraints];
        [self updateStatusLabel];
        
        self.userObserverToken = [ZMUser addUserObserver:self forUsers:@[user] inUserSession:[ZMUserSession sharedSession]];
    }
    
    return self;
}

- (void)createViews
{
    self.userImageView = [[UserImageView alloc] initWithMagicPrefix:@"content.system.participant.user_tile"];
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userImageView.user = self.user;
    [self addSubview:self.userImageView];
    
    self.statusLabel = [[UILabel alloc] initForAutoLayout];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.statusLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.statusLabel];
}

- (void)createConstraints
{
    [self.userImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:24];
    [self.userImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.userImageView autoSetDimensionsToSize:CGSizeMake(80, 80)];
    
    [self.statusLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.userImageView withOffset:12];
    [self.statusLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft relation:NSLayoutRelationGreaterThanOrEqual];
    [self.statusLabel autoPinEdgeToSuperviewMargin:ALEdgeRight relation:NSLayoutRelationGreaterThanOrEqual];
    [self.statusLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.statusLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)updateStatusLabel
{
    NSString *connectionStatusText = nil;
    
    if (! self.user.isConnected) {
        connectionStatusText = [[NSString stringWithFormat:NSLocalizedString(@"content.system.connecting_to", nil), self.user.name] uppercaseStringWithCurrentLocale];
    } else {
        connectionStatusText = [[NSString stringWithFormat:NSLocalizedString(@"content.system.connected_to", nil), self.user.name] uppercaseStringWithCurrentLocale];
    }
    
    self.statusLabel.text = connectionStatusText;
}


#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)note
{
    if (note.connectionStateChanged) {
        [self updateStatusLabel];
    }
}

@end
