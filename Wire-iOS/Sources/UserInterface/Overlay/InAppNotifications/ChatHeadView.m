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


#import "ChatHeadView.h"

// ui
#import "ContrastUserImageView.h"

// model
#import "WireSyncEngine+iOS.h"

// helpers
#import <PureLayout.h>
#import "WAZUIMagicIOS.h"
#import "Wire-Swift.h"

#import "NSString+EmoticonSubstitution.h"


@interface ChatHeadView ()
@property (nonatomic, strong) id<ZMConversationMessage>message;
@property (nonatomic, strong) ContrastUserImageView *userImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, assign) BOOL constraintsCreated;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *messageLabelLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *nameLabelRightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *messageLabelRightConstraint;

@end



@implementation ChatHeadView

- (instancetype)initWithMessage:(id<ZMConversationMessage>)message
{
    if (self = [super initWithFrame:CGRectZero]) {
        self.message = message;
        [self setup];
    }
    return self;
}

- (void)setImageToTextInset:(CGFloat)inset
{
    _imageToTextInset = inset;
    CGFloat tileToContentGap = [WAZUIMagic cgFloatForIdentifier:@"notifications.box_tile_to_content_gap"];

    self.nameLabelLeftConstraint.constant = inset + tileToContentGap;
    self.messageLabelLeftConstraint.constant = inset + tileToContentGap;
    self.nameLabelRightConstraint.constant = -[WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"] + inset;
    self.messageLabelRightConstraint.constant = -[WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"] + inset;
}

- (void)setMessageInCurrentConversation:(BOOL)messageInCurrentConversation
{
    _messageInCurrentConversation = messageInCurrentConversation;

    self.nameLabel.text = [self senderText];
}

- (void)setup
{
    self.backgroundColor = self.message.sender.accentColor;
    self.layer.cornerRadius = [WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapInAppNotification:)];
    [self addGestureRecognizer:tap];

    self.nameLabel = [[UILabel alloc] initForAutoLayout];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.nameLabel];
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.nameLabel.userInteractionEnabled = NO;
    self.nameLabel.text = [self senderText];
    self.nameLabel.font = [UIFont fontWithMagicIdentifier:@"notifications.user_name_font"];
    self.nameLabel.textColor = [UIColor colorWithMagicIdentifier:@"notifications.author_text_color"];
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.messageLabel = [[UILabel alloc] initForAutoLayout];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.messageLabel];
    self.messageLabel.backgroundColor = [UIColor clearColor];
    self.messageLabel.userInteractionEnabled = NO;
    self.messageLabel.text = [self messageText];
    self.messageLabel.font = [self messageFont];
    self.messageLabel.textColor = [UIColor colorWithMagicIdentifier:@"notifications.text_color"];
    self.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    self.userImageView = [[ContrastUserImageView alloc] initWithMagicPrefix:@"notifications"];
    self.userImageView.userSession = [ZMUserSession sharedSession];
    self.userImageView.userInteractionEnabled = NO;
    self.userImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.userImageView];
    self.userImageView.user = self.message.sender;
    self.userImageView.accessibilityIdentifier = @"ChatheadAvatarImage";

    [self setNeedsUpdateConstraints];
}

- (CGSize)intrinsicContentSize
{
    // A tile is always fixed height, but width can vary based on content
    return CGSizeMake(UIViewNoIntrinsicMetric, [WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"] * 2.0f);
}

- (NSString *)senderText
{
    NSString *nameString = [[self.message.sender displayName] uppercasedWithCurrentLocale];

    if (self.message.conversation.conversationType == ZMConversationTypeOneOnOne) { // 1 to 1 conversation
        return nameString;
    }
    else if ([self isMessageInCurrentConversation]) {
        return [NSString stringWithFormat:NSLocalizedString(@"notifications.this_conversation", @""), nameString];
    }
    else {
        return [NSString stringWithFormat:NSLocalizedString(@"notifications.in_conversation", @""), nameString, [self.message.conversation.displayName uppercasedWithCurrentLocale]];
    }
}

- (NSString *)messageText
{
    NSString *result = @"";

    if ([Message isTextMessage:self.message]) {
        
        result = [self.message.textMessageData.messageText stringByResolvingEmoticonShortcuts];
    }
    else if ([Message isImageMessage:self.message]) {
        result = NSLocalizedString(@"notifications.shared_a_photo", @"");
    }
    else if ([Message isKnockMessage:self.message]) {
        result = NSLocalizedString(@"notifications.pinged", @"");
    }
    else if ([Message isVideoMessage:self.message]) {
        result = NSLocalizedString(@"notifications.sent_video", @"");
    }
    else if ([Message isAudioMessage:self.message]) {
        result = NSLocalizedString(@"notifications.sent_audio", @"");
    }
    else if ([Message isFileTransferMessage:self.message]) {
        result = NSLocalizedString(@"notifications.sent_file", @"");
    }
    else if ([Message isLocationMessage:self.message]) {
        result = NSLocalizedString(@"notifications.sent_location", @"");
    }
    
    return result;
}

- (UIFont *)messageFont
{
    UIFont *font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];

    if (self.message.isEphemeral) {
        return [UIFont fontWithName:@"RedactedScript-Regular" size:font.pointSize];
    }

    return font;
}

- (void)didTapInAppNotification:(UITapGestureRecognizer *)tapper
{
    if (tapper.state == UIGestureRecognizerStateRecognized) {
        if (self.onSelect != nil) {
            self.onSelect(self.message);
        }
    }
}

#pragma mark - Utilities

- (void)updateConstraints
{
    if (! self.constraintsCreated) {
        self.constraintsCreated = YES;

        CGFloat tileDiameter = [WAZUIMagic cgFloatForIdentifier:@"notifications.tile_diameter"];
        CGFloat tileToContentGap = [WAZUIMagic cgFloatForIdentifier:@"notifications.box_tile_to_content_gap"];

        CGFloat topLabelInset = [WAZUIMagic cgFloatForIdentifier:@"notifications.top_label_inset"];
        CGFloat bottomLabelInset = [WAZUIMagic cgFloatForIdentifier:@"notifications.bottom_label_inset"];
        CGFloat ephemeralBottomLabelInset = [WAZUIMagic cgFloatForIdentifier:@"notifications.ephemeral_bottom_label_inset"];

        [self.userImageView autoSetDimension:ALDimensionHeight toSize:tileDiameter];
        [self.userImageView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        [self.userImageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.tile_left_margin"]];
        [self.userImageView autoConstrainAttribute:ALAttributeWidth toAttribute:ALAttributeHeight ofView:self.userImageView];

        [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:topLabelInset];
        self.nameLabelLeftConstraint = [self.nameLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.userImageView withOffset:tileToContentGap + self.imageToTextInset];
        self.nameLabelRightConstraint = [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"] - self.imageToTextInset];

        self.messageLabelLeftConstraint = [self.messageLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.userImageView withOffset:tileToContentGap + self.imageToTextInset];
        self.messageLabelRightConstraint = [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:[WAZUIMagic cgFloatForIdentifier:@"notifications.corner_radius"] - self.imageToTextInset];

        CGFloat bottomInset = self.message.isEphemeral ? ephemeralBottomLabelInset : bottomLabelInset;
        [self.messageLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:bottomInset];
    }

    [super updateConstraints];
}

@end
