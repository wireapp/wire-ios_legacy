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


#import "ConversationListIndicator.h"
#import "PingAnimationLayer.h"
#import "VoiceIndicatorLayer+MagicInit.h"
#import "UnreadIndicatorLayer.h"
#import "ConnectionRequestIndicatorLayer.h"
#import "UnsentIndicatorLayer.h"
#import "MissedCallIndicatorLayer.h"
#import "UIColor+WAZExtensions.h"
#import <WireExtensionComponents/WireStyleKit.h>
#import "UIImage+ZetaIconsNeue.h"


@interface ConversationListIndicator (ShowHide)

- (void)showUnreadIndicator;
- (void)showUnsentIndicator;
- (void)showConnectionRequestIndicator;
- (void)showMissedCallIndicator;
- (void)showCallIndicator;
- (void)showPingIndicator;
- (void)hidePingIndicator;

@end



@interface ConversationListIndicator ()

@property (nonatomic, strong) UnreadIndicatorLayer *unreadIndicator;
@property (nonatomic, strong) UnsentIndicatorLayer *unsentIndicator;
@property (nonatomic, strong) ConnectionRequestIndicatorLayer *connectionRequestIndicator;
@property (nonatomic, strong) CALayer *missedCallIndicatorLayer;
@property (nonatomic, strong) CALayer *callIndicatorLayer;
@property (nonatomic, strong) PingAnimationLayer *pingLayer;

@end



@implementation ConversationListIndicator


- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutAllLayers];
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)layoutAllLayers
{
    [self centerLayer:self.unreadIndicator];
    [self centerLayer:self.unsentIndicator];
    [self centerLayer:self.connectionRequestIndicator];
    [self centerLayer:self.pingLayer];
    [self centerLayer:self.callIndicatorLayer];
    [self centerLayer:self.missedCallIndicatorLayer];
}

- (void)centerLayer:(CALayer *)layer
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    [CATransaction commit];
}

- (void)hideAllIndicators
{
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    
    [self.unreadIndicator setHidden:YES];
    [self.missedCallIndicatorLayer setHidden:YES];
    [self.connectionRequestIndicator setHidden:YES];
    [self.unsentIndicator setHidden:YES];
    [self.callIndicatorLayer setHidden:YES];

    [self hidePingIndicator];
    
    [CATransaction commit];
}

- (void)setIndicatorType:(ZMConversationListIndicator)indicatorType
{
    if (_indicatorType == indicatorType) {
        return;
    }
    _indicatorType = indicatorType;
    
    [self hideAllIndicators];

    switch (indicatorType) {
            
        case ZMConversationListIndicatorUnreadMessages:
            [self showUnreadIndicator];
            break;
           
        case ZMConversationListIndicatorActiveCall:
        case ZMConversationListIndicatorInactiveCall:
            [self showCallIndicator];
            break;

        case ZMConversationListIndicatorKnock:
            [self showPingIndicator];
            break;
            
        case ZMConversationListIndicatorExpiredMessage:
            [self showUnsentIndicator];
            break;

        case ZMConversationListIndicatorMissedCall:
            [self showMissedCallIndicator];
            break;

        case ZMConversationListIndicatorPending:
            [self showConnectionRequestIndicator];
            break;
            
        default:
            break;
    }
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
    _unreadCount = unreadCount;
    
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    [self.unreadIndicator setUnreadCount:unreadCount];
    [CATransaction commit];
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;

    self.unreadIndicator.color = foregroundColor;
    self.connectionRequestIndicator.color = foregroundColor;
    self.pingLayer.color = foregroundColor;
}

- (BOOL)isDisplayingAnyIndicators
{
    return (self.indicatorType != ZMConversationListIndicatorNone || self.unreadCount != 0);
}

@end



@implementation ConversationListIndicator (ShowHide)

- (void)showUnreadIndicator
{
    if (self.unreadIndicator == nil) {
        self.unreadIndicator = [[UnreadIndicatorLayer alloc] initWithUnreadCount:self.unreadCount color:[UIColor accentColor]];
        [self.layer addSublayer:self.unreadIndicator];
        [self centerLayer:self.unreadIndicator];
    }
    [self.unreadIndicator setHidden:NO];
}

- (void)showUnsentIndicator
{
    if (self.unreadIndicator == nil) {
        self.unsentIndicator = [UnsentIndicatorLayer layer];
        [self.layer addSublayer:self.unsentIndicator];
        [self centerLayer:self.unsentIndicator];
    }
    [self.unsentIndicator setHidden:NO];
}

- (void)showConnectionRequestIndicator
{
    if (self.connectionRequestIndicator == nil) {
        self.connectionRequestIndicator = [ConnectionRequestIndicatorLayer layer];
        [self.layer addSublayer:self.connectionRequestIndicator];
        [self centerLayer:self.connectionRequestIndicator];
    }
    [self.connectionRequestIndicator setHidden:NO];
}

- (void)showMissedCallIndicator
{
    if (self.missedCallIndicatorLayer == nil) {
        self.missedCallIndicatorLayer = [self layerForIcon:ZetaIconTypeEndCall color:ZMAccentColorVividRed];
        [self.layer addSublayer:self.missedCallIndicatorLayer];
        [self centerLayer:self.missedCallIndicatorLayer];
    }
    [self.missedCallIndicatorLayer setHidden:NO];
}

- (void)showCallIndicator
{
    if (self.callIndicatorLayer == nil ) {
        self.callIndicatorLayer = [self layerForIcon:ZetaIconTypeCallAudio color:ZMAccentColorStrongLimeGreen];
        [self.layer addSublayer:self.callIndicatorLayer];
        [self centerLayer:self.callIndicatorLayer];
    }
    
    [self.callIndicatorLayer setHidden:NO];
}

- (void)showPingIndicator
{
    if (self.pingLayer == nil) {
        self.pingLayer = [[PingAnimationLayer alloc] initWithColor:[UIColor accentColor]];
        [self.layer addSublayer:self.pingLayer];
        [self centerLayer:self.pingLayer];
    }
    
    [self.pingLayer setHidden:NO];
    [self.pingLayer startAnimating];
}

- (void)hidePingIndicator
{
    [self.pingLayer stopAnimating];
    [self.pingLayer setHidden:YES];
}

- (CALayer *)layerForIcon:(ZetaIconType)icon color:(ZMAccentColor)color
{
    CALayer *layer = [CALayer layer];
    UIImage *image = [UIImage imageForIcon:icon iconSize:ZetaIconSizeTiny color:[UIColor colorForZMAccentColor:color]];
    layer.contents = (id)image.CGImage;
    layer.bounds = (CGRect){CGPointZero, image.size};
    return layer;
}

@end
