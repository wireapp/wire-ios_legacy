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


#import "Wire-Swift.h"
@import PureLayout;

#import "AudioPlaylistCell.h"



@implementation AudioPlaylistCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self =  [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        
        [self createViews];
        [self createConstraints];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    [self updateStyle];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    [self updateStyle];
}

- (void)updateStyle
{
    self.titleLabel.font = UIFont.smallRegularFont;
    self.titleLabel.textColor =  [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    self.durationLabel.textColor =  [UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantLight];
    
    if (self.highlighted) {
        self.titleLabel.textColor =  [UIColor accentColor];
    }
    else if (self.selected) {
        self.durationLabel.textColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
        self.titleLabel.font = UIFont.smallSemiboldFont;
    }
}

- (void)createViews
{
    self.titleLabel = [[UILabel alloc] initForAutoLayout];
    self.titleLabel.font = UIFont.smallRegularFont;
    self.titleLabel.textColor =  [UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark];
    [self.contentView addSubview:self.titleLabel];
    
    self.durationLabel = [[UILabel alloc] initForAutoLayout];
    self.durationLabel.font = UIFont.smallRegularFont;
    self.durationLabel.textColor =  [UIColor wr_colorFromColorScheme:ColorSchemeColorTextDimmed variant:ColorSchemeVariantLight];
    [self.contentView addSubview:self.durationLabel];
}

- (void)createConstraints
{
    [self.titleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeRight];
    [self.durationLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeft];
    
    [NSLayoutConstraint autoSetPriority:999 forConstraints:^{
        [self.titleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.durationLabel withOffset:-8 relation:NSLayoutRelationLessThanOrEqual];
    }];
    
    [self.durationLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
}

@end
