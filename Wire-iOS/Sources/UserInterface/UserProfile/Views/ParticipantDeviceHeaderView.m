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


#import "ParticipantDeviceHeaderView.h"
#import "ParticipantDeviceHeaderView+Internal.h"
@import PureLayout;
#import "WebLinkTextView.h"
#import "WireExtensionComponents.h"
#import "NSAttributedString+Wire.h"
#import "Wire-Swift.h"

@interface ParticipantDeviceHeaderView () <UITextViewDelegate>
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic, readwrite) NSString *userName;
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
    [self createViews];
    [self setupConstraints];

    [self setupStyle];
}

- (void)createViews
{
    self.textView = [[WebLinkTextView alloc] init];
    self.textView.textContainer.maximumNumberOfLines = 0;
    self.textView.delegate = self;
    self.textView.linkTextAttributes = @{};
    
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if ([self.delegate respondsToSelector:@selector(participantsDeviceHeaderViewDidTapLearnMore:)]) {
        [self.delegate participantsDeviceHeaderViewDidTapLearnMore:self];
    }
    return NO;
}

#pragma mark - Attributed Text

- (NSAttributedString *)attributedExplanationTextForUserName:(NSString *)userName showUnencryptedLabel:(BOOL)unencrypted
{
    if (unencrypted) {
        NSString *message = NSLocalizedString(@"profile.devices.fingerprint_message_unencrypted", nil);
        return [self attributedFingerprintForUserName:userName message:message];
    }
    else {
        NSString *message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"profile.devices.fingerprint_message.title", nil), NSLocalizedString(@"general.space_between_words", nil)];

        NSMutableAttributedString * mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString: [self attributedFingerprintForUserName:userName message:message]];

        NSString *fingerprintLearnMoreLink = NSLocalizedString(@"profile.devices.fingerprint_message.link", nil);

        [mutableAttributedString appendString:fingerprintLearnMoreLink attributes:[self linkAttributes]];

        return mutableAttributedString;
    }
}

- (NSMutableParagraphStyle *)paragraphStyleForFingerprint
{
    NSMutableParagraphStyle *paragraphStyle = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
    paragraphStyle.lineSpacing = 2;

    return paragraphStyle;
}

- (NSAttributedString *)attributedFingerprintForUserName:(NSString *)userName message:(NSString *)message
{
    NSString *fingerprintExplanation = [NSString stringWithFormat:message, userName];

    NSMutableParagraphStyle *paragraphStyle = [self paragraphStyleForFingerprint];

    NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName: self.textColor,
                                     NSFontAttributeName: self.font,
                                     NSParagraphStyleAttributeName: paragraphStyle
                                     };

    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:fingerprintExplanation
                                                                                       attributes:textAttributes];

    return [[NSAttributedString alloc] initWithAttributedString:attributedText];
}

- (NSDictionary *)linkAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [self paragraphStyleForFingerprint];

    NSDictionary *linkAttributes = @{
                                     NSFontAttributeName: self.font,
                                     NSForegroundColorAttributeName: self.linkAttributeColor,
                                     NSLinkAttributeName: NSURL.wr_fingerprintLearnMoreURL,
                                     NSParagraphStyleAttributeName: paragraphStyle
                                     };

    return linkAttributes;
}

@end
