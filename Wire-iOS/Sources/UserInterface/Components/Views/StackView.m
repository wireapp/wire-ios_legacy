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


#import "StackView.h"

@interface StackView ()
@property (nonatomic) CGSize contentSize;
@property (nonatomic) BOOL inLayout;
@end

@implementation StackView

- (void)setSpacing:(CGFloat)spacing
{
    _spacing = spacing;
    [self setNeedsLayout];
}

- (void)setDirection:(StackViewDirection)direction
{
    _direction = direction;
    [self setNeedsLayout];
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
    _contentInset = contentInset;
    [self setNeedsLayout];
}

- (void)addObservers:(UIView *)subview 
{
    [subview addObserver:self forKeyPath:@"frame" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"bounds" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"transform" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"position" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"zPosition" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"anchorPoint" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"anchorPointZ" options:0 context:NULL];
    [subview.layer addObserver:self forKeyPath:@"frame" options:0 context:NULL];  
}

- (void)removeObservers:(UIView *)subview
{
    [subview removeObserver:self forKeyPath:@"frame"];
    [subview.layer removeObserver:self forKeyPath:@"bounds"];
    [subview.layer removeObserver:self forKeyPath:@"transform"];
    [subview.layer removeObserver:self forKeyPath:@"position"];
    [subview.layer removeObserver:self forKeyPath:@"zPosition"];
    [subview.layer removeObserver:self forKeyPath:@"anchorPoint"];
    [subview.layer removeObserver:self forKeyPath:@"anchorPointZ"];
    [subview.layer removeObserver:self forKeyPath:@"frame"];
}

- (void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];

    [self addObservers:subview];
    
    [self setNeedsLayout];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (! self.inLayout) {
        [self setNeedsLayout];
    }
}

- (void)willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
    
    [self removeObservers:subview];
    
    [self setNeedsLayout];
}

- (BOOL)autoresizesSubviews
{
    return NO;
}

- (CGSize)intrinsicContentSize
{
    return self.contentSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.inLayout = YES;
    
    CGFloat __block offset = self.direction == StackViewDirectionHorizontal ? self.contentInset.left : self.contentInset.top;
    
    CGSize __block contentSize = CGSizeZero;
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        [subview layoutIfNeeded];
        
        if (subview.bounds.size.width != 0 && subview.bounds.size.height != 0 && subview.alpha != 0 && ! subview.isHidden) {            
            if (self.direction == StackViewDirectionHorizontal) {
                subview.frame = CGRectMake(offset, self.contentInset.top, subview.frame.size.width, subview.frame.size.height);
                contentSize.height = MAX(contentSize.height, subview.frame.size.height + self.contentInset.top + self.contentInset.bottom);
                offset+= self.spacing + subview.frame.size.width;
            }
            else {
                subview.frame = CGRectMake(self.contentInset.left, offset, subview.frame.size.width, subview.frame.size.height);
                contentSize.width = MAX(contentSize.width, subview.frame.size.width + self.contentInset.left + self.contentInset.right);
                offset+= self.spacing + subview.frame.size.height;
            }
        }
    }];
    
    if (self.direction == StackViewDirectionHorizontal) {        
        contentSize.width = offset - self.spacing + self.contentInset.right;
    }
    else {
        contentSize.height = offset - self.spacing + self.contentInset.bottom;
    }
    
    self.contentSize = contentSize;
    
    self.inLayout = NO;
    
    [self invalidateIntrinsicContentSize];
}

@end
