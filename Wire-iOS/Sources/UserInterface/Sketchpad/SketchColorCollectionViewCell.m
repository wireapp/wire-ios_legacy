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


#import "SketchColorCollectionViewCell.h"

@import PureLayout;
#import "ColorKnobView.h"



@interface SketchColorCollectionViewCell ()

@property (nonatomic) ColorKnobView *knobView;
@property (nonatomic) BOOL initialContraintsCreated;

@end

@implementation SketchColorCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.knobView = [[ColorKnobView alloc] initForAutoLayout];
        [self addSubview:self.knobView];
        
        _brushWidth = 6;
        
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)setSketchColor:(UIColor *)sketchColor
{
    if (_sketchColor == sketchColor) {
        return;
    }
    _sketchColor = sketchColor;
    
    self.knobView.knobColor = sketchColor;
}

- (void)setBrushWidth:(NSUInteger)brushWidth
{
    if (_brushWidth == brushWidth) {
        return;
    }
    _brushWidth = brushWidth;
    
    self.knobView.knobDiameter = brushWidth;
    [self.knobView setNeedsLayout];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.knobView.knobColor = self.sketchColor;
    self.knobView.selected = selected;
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.initialContraintsCreated) {
        return;
    }
    
    [self.knobView autoCenterInSuperview];
    
    [self.knobView autoSetDimension:ALDimensionHeight toSize:25];
    [self.knobView autoSetDimension:ALDimensionWidth toSize:25];
    
    self.initialContraintsCreated = YES;
}

@end
