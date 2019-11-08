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


#import "ColorKnobView.h"



@interface ColorKnobView ()

/// The actual circle knob, filled with the color
@property (nonatomic) CALayer *innerCircleLayer;
/// Just a layer, used for the thin border around the selected knob
@property (nonatomic) CALayer *borderCircleLayer;

@end

@implementation ColorKnobView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.knobDiameter = 6;
        
        CALayer *innerCircleLayer = [CALayer layer];
        self.innerCircleLayer = innerCircleLayer;
        [self.layer addSublayer:self.innerCircleLayer];
        
        CALayer *borderCircleLayer = [CALayer layer];
        self.borderCircleLayer = borderCircleLayer;
        [self.layer addSublayer:self.borderCircleLayer];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    CGPoint centerPos = (CGPoint){frame.size.width / 2, frame.size.height / 2};
    
    CGFloat knobDiameter = self.knobDiameter + 1;
    self.innerCircleLayer.bounds = (CGRect){{0, 0}, {knobDiameter, knobDiameter}};
    self.innerCircleLayer.position = centerPos;
    self.innerCircleLayer.cornerRadius = knobDiameter / 2;
    self.innerCircleLayer.borderWidth = 1.0;
    
    CGFloat knobBorderDiameter = knobDiameter + 6.0;
    self.borderCircleLayer.bounds = (CGRect){{0, 0}, {knobBorderDiameter, knobBorderDiameter}};
    self.borderCircleLayer.position = centerPos;
    self.borderCircleLayer.cornerRadius = knobBorderDiameter / 2;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    self.borderCircleLayer.borderColor = self.knobBorderColor.CGColor;
    self.borderCircleLayer.borderWidth = selected ? 1.0: 0.0;
}

- (void)setKnobColor:(UIColor *)knobColor
{
    _knobColor = knobColor;
    
    self.innerCircleLayer.backgroundColor = self.knobFillColor.CGColor;
    self.innerCircleLayer.borderColor = self.knobBorderColor.CGColor;
    self.borderCircleLayer.borderColor = self.knobBorderColor.CGColor;
}

#pragma mark - Helpers

- (UIColor *)knobBorderColor
{
    if ((self.knobColor == [UIColor whiteColor] && [ColorScheme defaultColorScheme].variant == ColorSchemeVariantLight) ||
        (self.knobColor == [UIColor blackColor] && [ColorScheme defaultColorScheme].variant == ColorSchemeVariantDark)) {
        return [UIColor lightGrayColor];
    }
    return self.knobColor;
}

- (UIColor *)knobFillColor
{
    return self.knobColor;
}

@end
