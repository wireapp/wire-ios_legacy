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


#import "CountryCodeView.h"

@import PureLayout;

#import "Wire-Swift.h"



@interface CountryCodeView ()

@property (nonatomic, readwrite) UIButton *button;
@property (nonatomic) UIView *separatorLine;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation CountryCodeView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.translatesAutoresizingMaskIntoConstraints = NO;
        self.button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.button.titleLabel.font = UIFont.normalLightFont;
        self.button.accessibilityIdentifier = @"CountryCodeButton";
        [self.button setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorTextForeground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark] forState:UIControlStateHighlighted];
        [self addSubview:self.button];
        
        self.separatorLine = [[UIView alloc] initForAutoLayout];
        self.separatorLine.backgroundColor = [UIColor wr_colorFromColorScheme:ColorSchemeColorButtonFaded variant:ColorSchemeVariantDark];
        [self addSubview:self.separatorLine];
    }
    
    [self setNeedsUpdateConstraints];
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        [self.button autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.separatorLine autoSetDimension:ALDimensionWidth toSize:1];
        [self.separatorLine autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeading];
    }
    
    [super updateConstraints];
}

@end
