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


#import "MissedCallCell.h"

#import <PureLayout/PureLayout.h>

#import "zmessaging+iOS.h"
#import "WireStyleKit.h"
#import "WAZUIMagicIOS.h"
#import "NSString+Wire.h"
#import "UIColor+Mixing.h"
#import "Analytics+iOS.h"
#import "UIColor+WR_ColorScheme.h"

@interface MissedCallCell () <ZMConversationObserver, ZMVoiceChannelStateObserver>

@property (nonatomic, strong) UIButton *missedCallButton;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) NSParagraphStyle *subtitleParagraphStyle;
@property (nonatomic) id <ZMConversationObserverOpaqueToken> conversationObserverToken;
@property (nonatomic) id <ZMVoiceChannelStateObserverOpaqueToken> voiceChannelStateObserverToken;

@end

@implementation MissedCallCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.burstTimestampSpacing = 12;
        self.messageContentView.preservesSuperviewLayoutMargins = NO;
        self.messageContentView.layoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.system_message.left_margin"],
                                                                 0, [WAZUIMagic floatForIdentifier:@"content.system_message.right_margin"]);
        [self createMissedCallViews];
        [self createConstraints];
    }
    
    return self;
}

- (void)dealloc
{
    [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    [self.message.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
    [self.message.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];
}

- (void)createMissedCallViews
{
    self.missedCallButton = [[UIButton alloc] init];
    self.missedCallButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.missedCallButton.adjustsImageWhenDisabled = NO;
    self.missedCallButton.accessibilityLabel = @"ConversationMissedCallButton";
    [self.missedCallButton addTarget:self action:@selector(callSender:) forControlEvents:UIControlEventTouchUpInside];
    [self.messageContentView addSubview:self.missedCallButton];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.minimumLineHeight = [WAZUIMagic cgFloatForIdentifier:@"content.system_message_line_height"];
    paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
    self.subtitleParagraphStyle = paragraphStyle;
    
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.subtitleLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    [self.messageContentView addSubview:self.subtitleLabel];
}

- (void)createConstraints
{
    [self.missedCallButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.missedCallButton autoPinEdgeToSuperviewEdge:ALEdgeTop];
    
    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.missedCallButton withOffset:12];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    if (message.conversation != self.message.conversation) {
        if (self.voiceChannelStateObserverToken != nil) {
            [self.message.conversation.voiceChannel removeVoiceChannelStateObserverForToken:self.voiceChannelStateObserverToken];
        }
        if (self.conversationObserverToken != nil) {
            [ZMConversation removeConversationObserverForToken:self.conversationObserverToken];
        }
        self.conversationObserverToken = [message.conversation addConversationObserver:self];
        self.voiceChannelStateObserverToken = [message.conversation.voiceChannel addVoiceChannelStateObserver:self];
    }
    
    [super configureForMessage:message layoutProperties:layoutProperties];
    
    [self updateMissedCallButton];
    
    NSString *subtitleText = nil;
    if (message.sender.isSelfUser) {
        subtitleText = [NSLocalizedString(@"content.system.you_wanted_to_talk", nil) uppercaseStringWithCurrentLocale];
    } else {
        subtitleText = [[NSString stringWithFormat:NSLocalizedString(@"content.system.other_wanted_to_talk", ), message.sender.displayName] uppercaseStringWithCurrentLocale];
    }
    
    self.subtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:subtitleText attributes:@{ NSParagraphStyleAttributeName: self.subtitleParagraphStyle }];
    
}

- (BOOL)lastMissedCallInConversation
{
    BOOL lastMissedCall = NO;
    
    for (ZMMessage* message in self.message.conversation.messages.reverseObjectEnumerator) {
        if ([Message isMissedCallMessage:message]) {
            if ([self.message isEqual:message]) {
                lastMissedCall = YES;
            }
            break;
        }
    }
    
    return lastMissedCall;
}

- (void)updateMissedCallButton
{
    BOOL lastMissedCall = [self lastMissedCallInConversation];
    
    self.missedCallButton.enabled = [self.message.conversation isCallingSupported] && lastMissedCall && self.message.conversation.voiceChannel.state == ZMVoiceChannelStateNoActiveUsers;
    self.missedCallButton.adjustsImageWhenDisabled = lastMissedCall;
    [self.missedCallButton setImage:[self missedCallImageForLastCall:lastMissedCall] forState:UIControlStateNormal];
}

- (UIImage *)missedCallImageForLastCall:(BOOL)lastCall
{
    if (lastCall) {
        return [WireStyleKit imageOfMissedcalllastWithAccent:self.message.sender.accentColor];
    }
    else {
        return [WireStyleKit imageOfMissedcallWithAccent:self.message.sender.accentColor];
    }
}

#pragma mark - Actions

- (void)callSender:(id)sender
{
    [self.message.conversation startAudioCallWithCompletionHandler:nil];
}

#pragma mark - ConversationObserver

- (void)conversationDidChange:(ConversationChangeInfo *)changeInfo
{
    if (changeInfo.messagesChanged) {
        [self updateMissedCallButton];
    }
}

#pragma mark - ZMVoiceChannelStateObserver

- (void)voiceChannelStateDidChange:(VoiceChannelStateChangeInfo *)change
{
    [self updateMissedCallButton];
}

@end
