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


#import "BackgroundView.h"
#import "WAZUIMagic.h"
#import "UIColor+MagicAccess.h"
#import "UIImage+ImageUtilities.h"

#import "Constants.h"
#import "UIView+MTAnimation.h"
#import "UIView+Borders.h"
#import "UIColor+WR_ColorScheme.h"
#import <PureLayout/PureLayout.h>


@interface BackgroundView ()

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIView *overlayContainer;
@property (nonatomic, strong) UIView *colorOverlay;
@property (nonatomic, strong) UIImageView *vignetteOverlay;

@property (nonatomic, strong) UIImage *vignetteImage;
/// Vignette to use when there is no user image
@property (nonatomic, strong) UIImage *vignetteImageNoPicture;

@property (nonatomic, assign) BOOL isShowingFlatColor;
@property (nonatomic, strong) UIColor *flatColor;

@end



@implementation BackgroundView

- (instancetype)initWithFilterColor:(UIColor *)filterColor
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _filterColor = filterColor;
        [self setupBackgroundView];
    }
    
    return self;
}

- (void)setupBackgroundView
{
    self.clipsToBounds = YES;
    
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.containerView];
    
    [UIView performWithoutAnimation:^{
        [self createImageView];
        [self createOverlays];
    }];
    
    [self createInitialConstraints];
    [self updateOverlayAppearanceWithVisibleImage:NO];
}

- (void)createImageView
{
    // Create a user image view
    self.imageView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.imageView];
    
    self.imageView.clipsToBounds = YES;
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = NO;
}

- (void)createOverlays
{
    self.overlayContainer = [[UIView alloc] init];
    self.overlayContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.overlayContainer];
    
    self.colorOverlay = [[UIView alloc] init];
    self.colorOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorOverlay.backgroundColor = self.filterColor;
    self.colorOverlay.alpha = [WAZUIMagic floatForIdentifier:@"background.color_overlay_opacity"];
    [self.overlayContainer addSubview:self.colorOverlay];
    
    self.vignetteOverlay = [[UIImageView alloc] init];
    self.vignetteOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    self.vignetteOverlay.backgroundColor = [UIColor clearColor];
    self.vignetteOverlay.layer.masksToBounds = YES;
    self.vignetteOverlay.contentMode = UIViewContentModeScaleToFill;
    [self.overlayContainer addSubview:self.vignetteOverlay];
}

- (CGSize)vignetteSize
{
    CGRect windowBounds = [UIApplication sharedApplication].keyWindow.bounds;
    CGFloat maxOverlayDimension = MAX(windowBounds.size.width, windowBounds.size.height);
    
    return (CGSize) {maxOverlayDimension, maxOverlayDimension};
}

- (UIImage *)vignetteImage
{
    if (_vignetteImage) {
        return _vignetteImage;
    }
    
    // setup
    UIColor *vignetteStartColor = [UIColor colorWithMagicIdentifier:@"background.vignette_start_color"];
    UIColor *vignetteEndColor = [UIColor colorWithMagicIdentifier:@"background.vignette_end_color"];

    CGFloat middleColorLocation = [[WAZUIMagic sharedMagic][@"background.vignette_color_position"] floatValue];
    CGFloat vignetteRadiusMultiplier = [[WAZUIMagic sharedMagic][@"background.vignette_radius_multiplier"] floatValue];
    
    UIImage *emptyImage = [UIImage imageWithColor:[UIColor clearColor] andSize:self.vignetteSize];
    _vignetteImage = [UIImage imageVignetteForRect:(CGRect) {{0, 0}, self.vignetteSize}
                                         ontoImage:emptyImage
                            showingImageUnderneath:YES
                                        startColor:vignetteStartColor
                                          endColor:vignetteEndColor
                                     colorLocation:middleColorLocation
                                  radiusMultiplier:vignetteRadiusMultiplier];

    return _vignetteImage;
}

- (UIImage *)vignetteImageNoPicture
{
    if (_vignetteImageNoPicture) {
        return _vignetteImageNoPicture;
    }
 
    UIColor *vignetteStartColor = [UIColor colorWithMagicIdentifier:@"background.vignette_start_color_without_image"];
    UIColor *vignetteEndColor = [UIColor colorWithMagicIdentifier:@"background.vignette_end_color_without_image"];
    
    CGFloat middleColorLocation = [[WAZUIMagic sharedMagic][@"background.vignette_color_position"] floatValue];
    CGFloat vignetteRadiusMultiplier = [[WAZUIMagic sharedMagic][@"background.vignette_radius_multiplier"] floatValue];
    
    
    UIImage *emptyImage = [UIImage imageWithColor:[UIColor clearColor] andSize:self.vignetteSize];
    _vignetteImageNoPicture = [UIImage imageVignetteForRect:(CGRect) {{0, 0}, self.vignetteSize}
                                                  ontoImage:emptyImage
                                     showingImageUnderneath:NO
                                                 startColor:vignetteStartColor
                                                   endColor:vignetteEndColor
                                              colorLocation:middleColorLocation
                                           radiusMultiplier:vignetteRadiusMultiplier];
    
    return _vignetteImageNoPicture;
}

- (void)createInitialConstraints
{
    [self.containerView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.colorOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.vignetteOverlay autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.imageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.overlayContainer autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)updateOverlayAppearanceWithVisibleImage:(BOOL)showingImage
{
    self.vignetteOverlay.contentMode = showingImage ? UIViewContentModeScaleToFill : UIViewContentModeScaleAspectFill;
    
    if (showingImage) {
        self.vignetteOverlay.image = self.vignetteImage;
        self.vignetteImageNoPicture = nil;
    }
    else {
        self.vignetteOverlay.image = self.vignetteImageNoPicture;
        self.vignetteImage = nil;
    }
}

- (void)setFilterColor:(UIColor *)filterColor
{
    [self setFilterColor:filterColor animated:YES];
}

- (void)setFilterColor:(UIColor *)filterColor animated:(BOOL)animated
{
    _filterColor = filterColor;
    
    void (^animationBlock)() = ^() {
        self.colorOverlay.backgroundColor = filterColor;
    };
    
    if (animated) {
        NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
        [UIView animateWithDuration:animationDuration animations:animationBlock];
    }
    else {
        animationBlock();
    }
}

- (void)setImageData:(NSData *)imageData animated:(BOOL)animated
{
    if (! imageData) {
        DDLogInfo(@"Setting nil data on background.");
        return;
    }
    
    [self transitionToImageWithData:imageData animated:animated];
}

- (void)setFlatColor:(UIColor *)color
{
    if (color == nil) {
        return;
    }

    _flatColor = color;
    self.isShowingFlatColor = YES;
    
    self.imageView.image = nil;
    
    [self updateAppearanceAnimated:YES];
}

- (void)transitionToImageWithData:(NSData *)imageData
                         animated:(BOOL)animated
{
    if (! imageData) {
        return;
    }
    self.isShowingFlatColor = NO;
    
    self.imageView.image = [UIImage imageWithData:imageData];
    [self updateAppearanceAnimated:animated];
}

@end



@implementation BackgroundView (Animations)

- (void)updateAppearanceAnimated:(BOOL)animated
{
    NSTimeInterval animationDuration = [WAZUIMagic floatForIdentifier:@"background.animation_duration"];
    
    void (^animationBlock)(void) = ^{
        
        if (self.isShowingFlatColor) {
            self.imageView.alpha = 0.0f;
            self.containerView.backgroundColor = self.flatColor;
            [self updateOverlayAppearanceWithVisibleImage:NO];
        }
        else {
            self.containerView.backgroundColor = nil;
            [self updateOverlayAppearanceWithVisibleImage:YES];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:animationDuration animations:animationBlock];
    }
    else {
        animationBlock();
    }
}

@end
