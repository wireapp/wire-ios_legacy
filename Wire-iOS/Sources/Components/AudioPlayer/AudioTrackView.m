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


#import "AudioTrackView.h"
@import WireExtensionComponents;
#import "AudioErrorView.h"
#import "Wire-Swift.h"

@import PureLayout;



@interface AudioTrackView ()

@property (nonatomic) IconButton *playPauseButton;
@property (nonatomic) UIImageView *artworkImageView;
@property (nonatomic) CAShapeLayer *progressLayer;
@property (nonatomic) CAShapeLayer *progressBackgroundLayer;
@property (nonatomic) AudioErrorView *errorView;
@property (nonatomic) BOOL initialConstraintsCreated;

@end

@implementation AudioTrackView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.artworkImageView = [[UIImageView alloc] initForAutoLayout];
        self.artworkImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.artworkImageView.layer.masksToBounds = YES;
        [self addSubview:self.artworkImageView];
        
        self.progressBackgroundLayer = [[CAShapeLayer alloc] init];
        self.progressBackgroundLayer.frame = [self progressLayerFrame];
        self.progressBackgroundLayer.lineWidth = 3;
        self.progressBackgroundLayer.fillColor = UIColor.clearColor.CGColor;
        self.progressBackgroundLayer.strokeColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
        [self.layer addSublayer:self.progressBackgroundLayer];
        
        self.progressLayer = [[CAShapeLayer alloc] init];
        self.progressLayer.frame = [self progressLayerFrame];
        self.progressLayer.lineWidth = 3;
        self.progressLayer.fillColor = UIColor.clearColor.CGColor;
        self.progressLayer.strokeColor = UIColor.soundcloudOrange.CGColor;
        [self.layer addSublayer:self.progressLayer];
        
        self.playPauseButton = [[IconButton alloc] initForAutoLayout];
        [self.playPauseButton setIcon:ZetaIconTypePlay withSize:ZetaIconSizeLarge forState:UIControlStateNormal];
        self.playPauseButton.layer.shadowOpacity = 1;
        self.playPauseButton.layer.shadowColor = UIColor.blackColor.CGColor;
        self.playPauseButton.layer.shadowRadius = 1;
        self.playPauseButton.layer.shadowOffset = CGSizeMake(0, 0);
        self.playPauseButton.accessibilityIdentifier = @"soundcloudPlayPauseButton";
        [self.playPauseButton setIconColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self addSubview:self.playPauseButton];
    }
    
    return self;
}

- (void)updateConstraints
{
    if (! self.initialConstraintsCreated) {
        
        self.initialConstraintsCreated = YES;
        
        [self.artworkImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        [self.playPauseButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.progressBackgroundLayer.frame = [self progressLayerFrame];
    self.progressBackgroundLayer.path = [self progressBeizerPath].CGPath;
    
    self.progressLayer.frame = [self progressLayerFrame];
    self.progressLayer.path = [self progressBeizerPath].CGPath;
    
    self.artworkImageView.layer.cornerRadius = self.artworkImageView.bounds.size.width / 2;
    _errorView.layer.cornerRadius = self.artworkImageView.bounds.size.width / 2;
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.progressLayer.strokeColor = tintColor.CGColor;
    self.artworkImageView.backgroundColor = [tintColor colorWithAlphaComponent:0.5];
}

- (void)setFailedToLoad:(BOOL)failedToLoad
{
    if (_failedToLoad == failedToLoad) {
        return;
    }
    _failedToLoad = failedToLoad;
    
    self.errorView.hidden = ! self.failedToLoad;
    self.playPauseButton.hidden = self.failedToLoad;
    self.artworkImageView.hidden = self.failedToLoad;
    
    self.progressBackgroundLayer.fillColor = self.failedToLoad ? [UIColor colorWithWhite:0.0f alpha:0.4f].CGColor : UIColor.clearColor.CGColor;
    self.progressBackgroundLayer.hidden = self.progress == 0 && ! self.failedToLoad;
    if (self.failedToLoad) {
        [self setProgress:0];
    }
}

- (CGRect)progressLayerFrame
{
    return self.artworkImageView.frame;
}

- (CGRect)progressLayerBounds
{
    return self.artworkImageView.bounds;
}

- (AudioErrorView *)errorView
{
    if (nil == _errorView) {
        _errorView = [[AudioErrorView alloc] initForAutoLayout];
        _errorView.layer.cornerRadius = self.artworkImageView.bounds.size.width / 2;

        [self addSubview:_errorView];
        [_errorView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    }
    
    return _errorView;
}

- (UIBezierPath *)progressBeizerPath
{
    const CGRect progressLayerBounds = [self progressLayerBounds];
    const CGFloat progressLayerInsets = self.progressLayer.lineWidth / 2;
    
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(progressLayerBounds, progressLayerInsets, progressLayerInsets)];
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(-progressLayerBounds.size.width / 2, -progressLayerBounds.size.height / 2);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(3 * M_PI_2 - 0.001);
    CGAffineTransform untranslate = CGAffineTransformMakeTranslation(progressLayerBounds.size.width / 2, progressLayerBounds.size.height / 2);
    
    [progressPath applyTransform:translate];
    [progressPath applyTransform:rotate];
    [progressPath applyTransform:untranslate];
    
    return progressPath;
}

- (void)setProgress:(CGFloat)progress
{
    [self setProgress:progress duration:0];
}

- (void)setProgress:(CGFloat)progress duration:(CGFloat)duration
{
    [CATransaction begin];
    [CATransaction setValue:@(duration) forKey:kCATransactionAnimationDuration];
    [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] forKey:kCATransactionAnimationTimingFunction];
 
    self.progressBackgroundLayer.hidden = progress == 0 && ! self.failedToLoad;
    self.progressLayer.strokeEnd = MAX(MIN(1, progress), 0);
    [CATransaction commit];
}

- (CGFloat)progress
{
    return self.progressLayer.strokeEnd;
}

@end
