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


#import "StartUIQuickActionsBar.h"
#import "IconButton.h"
#import "UIColor+WR_ColorScheme.h"
@import PureLayout;
#import <Classy/Classy.h>
@import WireExtensionComponents;
#import "Wire-Swift.h"

@interface StartUIQuickActionsBar ()

@property (nonatomic, readwrite) Button *inviteButton;
@property (nonatomic, readwrite) Button *conversationButton;
@property (nonatomic, readwrite) IconButton *cameraButton;
@property (nonatomic, readwrite) IconButton *callButton;
@property (nonatomic, readwrite) IconButton *videoCallButton;
@property (nonatomic) UIView *lineView;

@end


@implementation StartUIQuickActionsBar


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setOpaque:NO];
        self.backgroundColor = [UIColor clearColor];

        [self createLineView];
        [self createInviteButton];
        [self createConversationButton];
        [self createCameraButton];
        [self createCallButton];
        [self createVideoCallButton];
        [self createConstrains];
    }
    return self;
}

- (void)createInviteButton
{
    self.inviteButton = [Button buttonWithStyle:ButtonStyleEmpty variant:ColorSchemeVariantDark];
    self.inviteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.inviteButton];
    [self.inviteButton setTitle:NSLocalizedString(@"peoplepicker.invite_more_people", @"") forState:UIControlStateNormal];
}

- (void)createConversationButton
{
    self.conversationButton = [Button buttonWithStyle:ButtonStyleFull];
    self.conversationButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.conversationButton];
    [self.conversationButton setTitle:@"open" forState:UIControlStateNormal];
}

- (void)createCameraButton
{
    self.cameraButton = [[IconButton alloc] initForAutoLayout];
    [self.cameraButton setIcon:ZetaIconTypeCameraLens withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.cameraButton.circular = YES;
    self.cameraButton.cas_styleClass = @"actionBarButton";
    self.cameraButton.accessibilityIdentifier = @"actionBarCameraButton";

    [self addSubview:self.cameraButton];
}

- (void)createCallButton
{
    self.callButton = [[IconButton alloc] initForAutoLayout];
    [self.callButton setIcon:ZetaIconTypePhone withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.callButton.circular = YES;
    self.callButton.cas_styleClass = @"actionBarButton";
    self.callButton.accessibilityIdentifier = @"actionBarCallButton";

    [self addSubview:self.callButton];
}

- (void)createVideoCallButton
{
    self.videoCallButton = [[IconButton alloc] initForAutoLayout];
    [self.videoCallButton setIcon:ZetaIconTypeVideoCall withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    self.videoCallButton.circular = YES;
    self.videoCallButton.cas_styleClass = @"actionBarButton";
    self.videoCallButton.accessibilityIdentifier = @"actionBarVideoCallButton";
    
    [self addSubview:self.videoCallButton];
}

- (void)createLineView
{
    self.lineView = [[UIView alloc] initForAutoLayout];
    self.lineView.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSeparator variant:ColorSchemeVariantDark];
    [self addSubview:self.lineView];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self invalidateIntrinsicContentSize];
}

- (void)setMode:(StartUIQuickActionBarMode)mode
{
    _mode = mode;
    self.inviteButton.hidden = (mode != StartUIQuickActionBarModeInvite);
    self.conversationButton.hidden = (mode == StartUIQuickActionBarModeInvite);
    self.cameraButton.hidden = (mode == StartUIQuickActionBarModeInvite);
    self.callButton.hidden = (mode == StartUIQuickActionBarModeInvite);
    self.videoCallButton.hidden = (mode != StartUIQuickActionBarModeOpenConversation) ;

    NSString *conversationButtonTitle = @"";
    if (mode == StartUIQuickActionBarModeOpenConversation || mode == StartUIQuickActionBarModeOpenGroupConversation) {
        conversationButtonTitle = NSLocalizedString(@"peoplepicker.quick-action.open-conversation", @"");
    } else if (mode == StartUIQuickActionBarModeCreateConversation) {
        conversationButtonTitle = NSLocalizedString(@"peoplepicker.quick-action.create-conversation", @"");
    }
    [self.conversationButton setTitle:conversationButtonTitle
                             forState:UIControlStateNormal];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, (self.hidden) ? 0 : 56.0f);
}

- (void)createConstrains
{
    [self.inviteButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.inviteButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset: 24];
    [self.inviteButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset: 24];
    [self.inviteButton autoSetDimension:ALDimensionHeight toSize:28];
    
    [self.conversationButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.conversationButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset: 24];
        
    [self.cameraButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.cameraButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:24];
    [self autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.cameraButton withOffset:24];
    
    [self.callButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.callButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.cameraButton withOffset:-24];

    [self.videoCallButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.videoCallButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.callButton withOffset:-24];
    
    [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.lineView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.lineView autoSetDimension:ALDimensionHeight toSize:0.5];
    
    CGSize buttonSize = CGSizeMake(32, 32);
    [self.callButton autoSetDimensionsToSize:buttonSize];
    [self.cameraButton autoSetDimensionsToSize:buttonSize];
    [self.videoCallButton autoSetDimensionsToSize:buttonSize];
}

@end
