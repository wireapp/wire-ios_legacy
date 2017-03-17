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


#import "UserImageView.h"
#import <PureLayout/PureLayout.h>
@import zmessaging;
#import "ImageCache.h"
#import "UIImage+ImageUtilities.h"
#import "UIImage+ZetaIconsNeue.h"

#import "weakify.h"


CGFloat PixelSizeForUserImageSize(UserImageViewSize size);
CGFloat PointSizeForUserImageSize(UserImageViewSize size);

CGFloat PixelSizeForUserImageSize(UserImageViewSize size)
{
    return PointSizeForUserImageSize(size) * [UIScreen mainScreen].scale;
}

CGFloat PointSizeForUserImageSize(UserImageViewSize size)
{
    switch (size) {
        case UserImageViewSizeTiny:
            return 36.0f;
            break;
        case UserImageViewSizeSmall:
            return 56.0f;
            break;
        case UserImageViewSizeNormal:
            return 64.0f;
            break;
        case UserImageViewSizeBig:
            return 320.0f;
            break;
        default:
            break;
    }
    return 0;
}


typedef void (^ImageCacheCompletionBlock)(id , NSString *);



static CIContext *ciContext(void)
{
    static CIContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [CIContext contextWithOptions:nil];
    });
    return context;
}

@interface UserImageView ()

@property (nonatomic) id userObserverToken;
@property (nonatomic) UIView *indicator;

@end



@implementation UserImageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupBasicProperties];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupBasicProperties];
    }
    return self;
}

- (instancetype)initWithSize:(UserImageViewSize)size
{
    self = [self initWithFrame:CGRectZero];

    if (self) {
        self.size = size;
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateIndicatorCornerRadius];
}

- (void)setupBasicProperties
{
    _shouldDesaturate = YES;
    _size = UserImageViewSizeNormal;
    
    [self createIndicator];
    [self createConstraints];
    [self updateIndicatorCornerRadius];
}

- (void)updateIndicatorCornerRadius
{
    self.indicator.layer.cornerRadius = self.indicator.bounds.size.width / 2;
}

- (CGSize)intrinsicContentSize
{
    CGFloat imageSize = PointSizeForUserImageSize(self.size);
    return CGSizeMake(imageSize, imageSize);
}

- (void)setUser:(id<ZMBareUser, AccentColorProvider>)user
{    
    _user = user;
    
    if (user != nil && ([user isKindOfClass:[ZMUser class]] || [user isKindOfClass:[ZMSearchUser class]])) {
        self.userObserverToken = [UserChangeInfo addObserver:self forBareUser:user];
    }
    
    self.initials.textColor = UIColor.whiteColor;
    self.initials.text = user.initials.uppercaseString;
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self setUserImage:nil];
    [self updateIndicatorColor];
    [self updateUserImage];
}

- (void)createIndicator
{
    self.indicator = [[UIView alloc ] initForAutoLayout];
    self.indicator.backgroundColor = UIColor.redColor;
    self.indicator.hidden = YES;
    
    [self addSubview:self.indicator];
}

- (void)createConstraints
{
    [self.indicator autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.indicator autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.indicator autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.containerView withMultiplier:1.0f / 3.0f];
    [self.indicator autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.indicator];
}

- (void)updateIndicatorColor
{
    self.indicator.backgroundColor = [(id)self.user accentColor];
}

- (void)updateUserImage
{
    if (self.size == UserImageViewSizeBig &&
        self.user.imageMediumData == nil) {
        
        if ([self.user respondsToSelector:@selector(requestMediumProfileImageInUserSession:)]) {
            [(id)self.user requestMediumProfileImageInUserSession:self.userSession];
        }
        return;
    }
    
    if (self.size != UserImageViewSizeBig &&
        self.user.imageSmallProfileData == nil) {
        
        if ([self.user respondsToSelector:@selector(requestSmallProfileImageInUserSession:)]) {
            [(id)self.user requestSmallProfileImageInUserSession:self.userSession];
        }
        return;
    }
    
    NSData *imageData = nil;
    NSString *imageCacheKey = nil;
    
    if (self.size == UserImageViewSizeBig) {
        imageData = self.user.imageMediumData;
        imageCacheKey = self.user.imageMediumIdentifier;
    }
    else {
        imageData = self.user.imageSmallProfileData;
        imageCacheKey = self.user.imageSmallProfileIdentifier;
    }
    BOOL userIsConnected = self.user.isConnected || self.user.isSelfUser;

    if (imageData == nil || imageCacheKey == nil) {
        return;
    }

    // cache key is not changed when user change his own image
    if (self.user.isSelfUser) {
        
        UIImage *image = [UIImage imageFromData:imageData withMaxSize:PixelSizeForUserImageSize(self.size)];

        [self setUserImage:image];
        return;
    }

    @weakify(self);
    
    ImageCacheCompletionBlock completionBlock = ^void(id image, NSString *cacheKey){
        
        @strongify(self);
        
        NSString *updatedCacheKey = nil;
        
        if (self.size == UserImageViewSizeBig) {
            updatedCacheKey = self.user.imageMediumIdentifier;
        }
        else {
            updatedCacheKey = self.user.imageSmallProfileIdentifier;
        }
        
        if ([cacheKey isEqualToString:updatedCacheKey]) {
            [self setUserImage:image];
        }
    };
    
    if (userIsConnected || ! self.shouldDesaturate) {
        [[UserImageView sharedFullColorImageCacheForSize:self.size] imageForData:imageData cacheKey:imageCacheKey creationBlock:^id(NSData *data) {
            
            UIImage *image = [UIImage imageFromData:data withMaxSize:PixelSizeForUserImageSize(self.size)];
            return image;
            
        } completion:completionBlock];
    }
    else {
        [[UserImageView sharedDesaturatedImageCacheForSize:self.size] imageForData:imageData cacheKey:imageCacheKey creationBlock:^id(NSData *data) {
            
            UIImage *image = [[UserImageView sharedFullColorImageCacheForSize:self.size] imageForCacheKey:imageCacheKey];
            
            if (! image) {
                image = [UIImage imageFromData:data withMaxSize:PixelSizeForUserImageSize(self.size)];
            }
            image = [image desaturatedImageWithContext:ciContext()
                                            saturation:0];
          
            return image;
            
        } completion:completionBlock];
    }
}

- (void)setUserImage:(UIImage *)userImage
{
    self.initials.hidden = userImage != nil;
    self.imageView.hidden = userImage == nil;
    self.imageView.image = userImage;
    
    if (userImage) {
        self.containerView.backgroundColor = UIColor.clearColor;
    }
    else if (self.user.isConnected || self.user.isSelfUser) {
        self.containerView.backgroundColor = [self.user accentColor];
    }
    else {
        self.containerView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if ([self.delegate respondsToSelector:@selector(userImageViewTouchUpInside:)]) {
        [self.delegate userImageViewTouchUpInside:self];
    }
}

#pragma mark - Indicator

- (void)setIndicatorEnabled:(BOOL)indicatorEnabled
{
    _indicatorEnabled = indicatorEnabled;
    
    self.indicator.hidden = ! indicatorEnabled;
}

#pragma mark - ZMUserObserver

- (void)userDidChange:(UserChangeInfo *)change
{
    if (self.size == UserImageViewSizeBig) {
        if (change.imageMediumDataChanged || change.connectionStateChanged) {
            [self updateUserImage];
        }
    }
    else {
        if (change.imageSmallProfileDataChanged || change.connectionStateChanged) {
            [self updateUserImage];
        }
    }
    
    if (change.accentColorValueChanged) {
        [self updateIndicatorColor];
    }
}

#pragma mark - Class Methods

+ (ImageCache *)sharedFullColorImageCacheForSize:(UserImageViewSize)size
{
    static NSArray *fullColorImageCaches;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *fullColorImageCachesMutable = [NSMutableArray arrayWithCapacity:UserImageViewSizeLast - UserImageViewSizeFirst];
        
        for (UserImageViewSize s = UserImageViewSizeFirst; s <= UserImageViewSizeLast; s++) {            
            ImageCache *fullColorImageCache = [[ImageCache alloc] initWithName:[NSString stringWithFormat:@"_UserImageView.fullColorImageCache_%d", (int)s]];
            fullColorImageCache.maxConcurrentOperationCount = 4;
            fullColorImageCache.countLimit = 100;
            fullColorImageCache.totalCostLimit = 1024 * 1024 * 10;
            fullColorImageCache.qualityOfService = NSQualityOfServiceUtility;
            [fullColorImageCachesMutable addObject:fullColorImageCache];
        }
        
        fullColorImageCaches = fullColorImageCachesMutable;
    });
    return fullColorImageCaches[size];
}

+ (ImageCache *)sharedDesaturatedImageCacheForSize:(UserImageViewSize)size
{
    static NSArray *desaturatedImageCaches;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *desaturatedImageCachesMutable = [NSMutableArray arrayWithCapacity:UserImageViewSizeLast - UserImageViewSizeFirst];
        
        for (UserImageViewSize s = UserImageViewSizeFirst; s <= UserImageViewSizeLast; s++) {            
            ImageCache *desaturatedImageCache = [[ImageCache alloc] initWithName:[NSString stringWithFormat:@"_UserImageView.desaturatedImageCache_%d", (int)s]];
            desaturatedImageCache.maxConcurrentOperationCount = 4;
            desaturatedImageCache.countLimit = 100;
            desaturatedImageCache.totalCostLimit = 1024 * 1024 * 10;
            desaturatedImageCache.qualityOfService = NSQualityOfServiceUtility;
            [desaturatedImageCachesMutable addObject:desaturatedImageCache];
        }
        
        desaturatedImageCaches = desaturatedImageCachesMutable;
    });
    return desaturatedImageCaches[size];
}

@end
