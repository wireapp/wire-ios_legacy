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


#import "ParticipantsDeviceHeaderView.h"
@import PureLayout;
#import "WebLinkTextView.h"
#import "WAZUIMagicIOS.h"
#import "NSURL+WireURLs.h"
#import "WireExtensionComponents.h"

@import Classy;

@interface ParticipantDeviceHeaderView () <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic, readwrite) NSString *userName;
@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *linkAttributeColor;
@end



@implementation ParticipantDeviceHeaderView

- (instancetype)initWithUserName:(NSString *)userName
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _userName = userName;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = UIColor.clearColor;
    [[CASStyler defaultStyler] styleItem:self];
    [self createViews];
    [self setupConstraints];
}

- (void)createViews
{
    self.textView = [[WebLinkTextView alloc] init];
    self.textView.textContainer.maximumNumberOfLines = 0;
    self.textView.delegate = self;
    
    [self addSubview:self.textView];
}

- (void)setShowUnencryptedLabel:(BOOL)showUnencryptedLabel
{
    self.textView.attributedText = [self attributedExplanationTextForUserName:self.userName showUnencryptedLabel:showUnencryptedLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.textView setNeedsUpdateConstraints];
    [self.textView updateConstraintsIfNeeded];
}

- (void)setupConstraints
{
    [self.textView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(40, 24, 16, 24)];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if ([self.delegate respondsToSelector:@selector(participantsDeviceHeaderViewDidTapLearnMore:)]) {
        [self.delegate participantsDeviceHeaderViewDidTapLearnMore:self];
    }
    return YES;
}

#pragma mark - Attributed Text

- (NSAttributedString *)attributedExplanationTextForUserName:(NSString *)userName showUnencryptedLabel:(BOOL)unencrypted
{
    NSString *message = NSLocalizedString(unencrypted ? @"profile.devices.fingerprint_message_unencrypted" : @"profile.devices.fingerprint_message", nil);
    return [self attributedFingerprintExplanationForUserName:userName message:message];
}

- (NSAttributedString *)attributedFingerprintExplanationForUserName:(NSString *)userName message:(NSString *)message
{
    NSString *fingerprintExplanation = [NSString stringWithFormat:message, userName];
    NSString *fingerprintLearnMoreLink = NSLocalizedString(@"profile.devices.fingerprint_message.link", nil);
    NSRange learnMoreLinkRange = [fingerprintExplanation rangeOfString:fingerprintLearnMoreLink];

    NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSFontAttributeName: self.font
                                     };

    NSDictionary *linkAttributes = @{
                                     NSFontAttributeName: self.font,
                                     NSForegroundColorAttributeName: self.linkAttributeColor,
                                     NSLinkAttributeName: NSURL.wr_fingerprintLearnMoreURL
                                     };

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fingerprintExplanation
                                                                                       attributes:textAttributes];

    [attributedText addAttributes:linkAttributes range:learnMoreLinkRange];
    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

@end
