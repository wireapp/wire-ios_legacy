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



#import "SearchSectionHeaderView.h"
#import <PureLayout/PureLayout.h>
#import "WAZUIMagic.h"
#import "UIFont+MagicAccess.h"
#import "UIColor+MagicAccess.h"
#import "Wire-Swift.h"

#import "UIView+Borders.h"

NSString *const PeoplePickerHeaderReuseIdentifier = @"PeoplePickerHeaderReuseIdentifier";

@interface SearchSectionHeaderView ()
@property (nonatomic, strong) UILabel *titleField;
@end



@implementation SearchSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupPeoplePickerHeader];
        [self setColorSchemeVariant:ColorSchemeVariantDark];
    }

    return self;
}

- (void)setupPeoplePickerHeader
{
    self.titleField = [[UILabel alloc] initWithFrame:CGRectZero];

    self.titleField.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.textAlignment = NSTextAlignmentLeft;
    self.titleField.numberOfLines = 0;
    self.titleField.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    [self addSubview:self.titleField];
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0f];
    CGFloat leftInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.left_padding"];
    [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:leftInset];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    self.titleField.text = [_title uppercasedWithCurrentLocale];
}

- (void)setColorSchemeVariant:(ColorSchemeVariant)colorSchemeVariant
{
    _colorSchemeVariant = colorSchemeVariant;
    
    self.titleField.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSectionText variant:self.colorSchemeVariant];
    self.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorSectionBackground variant:self.colorSchemeVariant];
}

@end
