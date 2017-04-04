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


#import "NameChangedCell.h"
#import "WAZUIMagicIOS.h"
#import "UIColor+MagicAccess.h"
#import "WireSyncEngine+iOS.h"
#import "UIColor+WAZExtensions.h"
#import "UIColor+WR_ColorScheme.h"

#import <PureLayout/PureLayout.h>



@interface NameChangedCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

@end



@implementation NameChangedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.messageContentView.preservesSuperviewLayoutMargins = NO;
        self.messageContentView.layoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.system_message.left_margin"],
                                                                 0, [WAZUIMagic floatForIdentifier:@"content.system_message.right_margin"]);
        [self createNameChangedViews];
        [self createConstraints];
    }
    
    return self;
}

- (void)createNameChangedViews
{
    UIFont *titleFont = [UIFont fontWithMagicIdentifier:@"style.text.large.font_spec_thin"];
    UIColor *titleColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    UIFont *subtitleFont = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_bold"];
    UIColor *subtitleColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground];
    
    self.titleLabel = [self.class createLabel];
    self.titleLabel.font = titleFont;
    self.titleLabel.textColor = titleColor;
    [self.messageContentView addSubview:self.titleLabel];
    
    self.subtitleLabel = [self.class createLabel];
    self.subtitleLabel.font = subtitleFont;
    self.subtitleLabel.textColor = subtitleColor;
    [self.messageContentView addSubview:self.subtitleLabel];
}

+ (UILabel *)createLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    
    return label;
}

- (void)createConstraints
{
    [self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft relation:NSLayoutRelationGreaterThanOrEqual];
    [self.titleLabel autoPinEdgeToSuperviewMargin:ALEdgeRight relation:NSLayoutRelationGreaterThanOrEqual];
    
    [self.subtitleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:8];
    [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeft relation:NSLayoutRelationGreaterThanOrEqual];
    [self.subtitleLabel autoPinEdgeToSuperviewMargin:ALEdgeRight relation:NSLayoutRelationGreaterThanOrEqual];
    [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.subtitleLabel.text = nil;
}

- (void)configureForMessage:(id<ZMConversationMessage>)message layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    if (! [Message isSystemMessage:message]) {
        return;
    }
    
    [super configureForMessage:message layoutProperties:layoutProperties];
    
    NSString *titleText = message.systemMessageData.text;
    NSString *subtitleText = nil;
    
    if (message.sender.isSelfUser) {
        
        NSString *stringKey = @"content.system.you_renamed_conv";
        if (! titleText.length) {
            stringKey = @"content.system.you_renamed_conv_to_nothing";
        }
        subtitleText = [NSLocalizedString(stringKey, @"") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    else {
        NSString *stringKey = @"content.system.other_renamed_conv";
        
        if (! titleText.length) {
            stringKey = @"content.system.other_renamed_conv_to_nothing";
        }
        
        NSString *tmp = [NSString stringWithFormat:NSLocalizedString(stringKey, @""), message.sender.displayName];
        subtitleText = [tmp uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    
    self.titleLabel.text = titleText;
    self.subtitleLabel.text = subtitleText;
}

@end
