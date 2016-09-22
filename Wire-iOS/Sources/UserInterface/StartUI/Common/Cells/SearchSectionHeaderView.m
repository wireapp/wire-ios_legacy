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
#import "NSString+Wire.h"

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
    }

    return self;
}

- (void)setupPeoplePickerHeader
{
    self.titleField = [[UILabel alloc] initWithFrame:CGRectZero];

    self.titleField.font = [UIFont fontWithMagicIdentifier:@"style.text.small.font_spec_light"];
    self.titleField.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    self.titleField.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleField.textAlignment = NSTextAlignmentLeft;
    self.titleField.numberOfLines = 0;
    self.titleField.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    self.backgroundColor = [UIColor colorWithMagicIdentifier:@"people_picker.section_header.background_color"];
    [self addSubview:self.titleField];
    [self setupConstraints];
}

- (void)setupConstraints
{
    [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10.0f];
    CGFloat leftInset = [WAZUIMagic floatForIdentifier:@"people_picker.top_conversations_mode.left_padding"];
    [self.titleField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:leftInset];
}

- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    self.titleField.text = [_title uppercaseStringWithCurrentLocale];
}

@end
