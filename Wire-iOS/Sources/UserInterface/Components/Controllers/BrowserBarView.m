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


#import <PureLayout/PureLayout.h>
#import <Classy/Classy.h>

#import "BrowserBarView.h"
@import WireExtensionComponents;

@interface BrowserBarView ()

@property (nonatomic) CAShapeLayer *progressLayer;
@property (nonatomic) BOOL initialConstraintsCreated;
@property (nonatomic) BOOL useWithStatusBar;

@end

@implementation BrowserBarView

- (instancetype)init
{
    return [self initForUseWithStatusBar:NO];
}

- (instancetype)initForUseWithStatusBar:(BOOL)statusBar
{
    self = [super init];
    if (self) {
        self.useWithStatusBar = statusBar;

        self.shareButton = [IconButton iconButtonCircular];
        self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.shareButton setIcon:ZetaIconTypeExport withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self addSubview:self.shareButton];

        self.closeButton = [IconButton iconButtonCircular];
        self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.closeButton setIcon:ZetaIconTypeX withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
        [self addSubview:self.closeButton];

        self.titleLabel = [[UILabel alloc] initForAutoLayout];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.titleLabel];

        self.progressLayer = [[CAShapeLayer alloc] init];
        self.progressLayer.frame = [self progressLayerFrame];
        self.progressLayer.strokeColor = [UIColor redColor].CGColor;
        self.progressLayer.strokeEnd = 0;
        self.progressLayer.lineWidth = 2;
        [self.layer addSublayer:self.progressLayer];
    }

    return self;
}

- (void)updateConstraints
{
    if(! self.initialConstraintsCreated) {
        self.initialConstraintsCreated = YES;

        CGFloat offset = self.useWithStatusBar ? 10 : 0;
        [self.shareButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16];
        [self.shareButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
        [self.shareButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self withOffset:offset];
        
        [self.closeButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
        [self.closeButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self withOffset:offset];
        [self.closeButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
        
        [self.titleLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.shareButton withOffset:16];
        [self.titleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeLeft ofView:self.closeButton withOffset:-16];
        [self.titleLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self withOffset:offset];
    }
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.progressLayer.frame = [self progressLayerFrame];
    self.progressLayer.path = [self progressBeizerPath].CGPath;
}

- (CGRect)progressLayerFrame
{
    return CGRectMake(self.bounds.origin.x,
                      self.bounds.origin.y + self.progressLayer.lineWidth / 2,
                      self.bounds.size.width,
                      0);
}

- (UIBezierPath *)progressBeizerPath
{
    const CGRect progressLayerFrame = [self progressLayerFrame];
    const CGRect progressLayerBounds = CGRectMake(0, 0, progressLayerFrame.size.width, progressLayerFrame.size.height);
    
    return [UIBezierPath bezierPathWithRect:progressLayerBounds];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    self.progressLayer.strokeEnd = progress;
    
    if (progress >= 1.0) {
        self.progressLayer.opacity = 0;
    }
}

@end
