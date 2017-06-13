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


#import "GuidanceDotView.h"

@import PureLayout;

#import "WAZUIMagicIOS.h"



@interface GuidanceDotView ()

@property (nonatomic) UIView *dot;
@property (nonatomic) BOOL initialConstraintsCreated;

@end



@implementation GuidanceDotView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.dot = [[UIView alloc] initForAutoLayout];
        self.dot.translatesAutoresizingMaskIntoConstraints = NO;
        self.dot.backgroundColor = [UIColor colorWithMagicIdentifier:@"guidance.guidance_type_required_color"];;
        [self addSubview:self.dot];
    }
    
    [self setNeedsUpdateConstraints];
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;
        
        CGFloat dotDiameter = [WAZUIMagic cgFloatForIdentifier:@"guidance.dot_size"];
        
        self.dot.layer.cornerRadius = dotDiameter / 2.0;
        [self.dot autoSetDimensionsToSize:CGSizeMake(dotDiameter, dotDiameter)];
        [self.dot autoCenterInSuperview];
    }
    
    [super updateConstraints];
}

@end
