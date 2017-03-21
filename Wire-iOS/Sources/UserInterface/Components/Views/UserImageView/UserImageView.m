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
#import <zmessaging/ZMBareUser+UserSession.h>
#import <ZMCDataModel/ZMBareUser.h>
#import <PureLayout/PureLayout.h>

#import "zmessaging+iOS.h"
#import "ImageCache.h"
#import "UIImage+ImageUtilities.h"
#import "UIImage+ZetaIconsNeue.h"
#import "WAZUIMagicIOS.h"


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

- (instancetype)initWithMagicPrefix:(NSString *)magicPrefix
{
    self = [self initWithFrame:CGRectZero];

    if (self) {
        [self setupWithMagicPrefix:magicPrefix];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.indicator.layer.cornerRadius = self.indicator.bounds.size.width / 2;
}


- (void)setupBasicProperties
{
    _borderColorMatchesAccentColor = YES;
    _shouldDesaturate = YES;
    _suggestedImageSize = UserImageViewSizeNormal;
    
    [self createIndicator];
    [self createConstraints];
}

- (CGSize)intrinsicContentSize
{
    CGFloat imageSize = PointSizeForUserImageSize(self.suggestedImageSize);
    return CGSizeMake(imageSize, imageSize);
}

- (void)setUser:(id<ZMBareUser, ZMSearchableUser>)user
{    
    _user = user;
    
    if (user != nil && ([user isKindOfClass:[ZMUser class]] || [user isKindOfClass:[ZMSearchUser class]])) {
        self.userObserverToken = [UserChangeInfo addObserver:self forBareUser:user];
    }
    
    self.initials.textColor = UIColor.whiteColor;
    self.initials.text = user.initials.uppercaseString;
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self setUserImage:nil];
    [self updateBorderColor];
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

- (void)updateBorderColor
{
    if (! self.borderColorMatchesAccentColor) {
        return;
    }
    
    if (self.user.isConnected || self.user.isSelfUser) {
        self.borderColor = [(id)self.user accentColor];
    } else {
        self.borderColor = [UIColor clearColor];
    }
}

- (void)updateUserImage
{
    if (self.suggestedImageSize == UserImageViewSizeBig &&
        self.user.imageMediumData == nil) {
        
        [self.user requestMediumProfileImageInUserSession:[ZMUserSession sharedSession]];
        return;
    }
    
    if (self.suggestedImageSize != UserImageViewSizeBig &&
        self.user.imageSmallProfileData == nil) {
        
        [self.user requestSmallProfileImageInUserSession:[ZMUserSession sharedSession]];
        return;
    }
    
    NSData *imageData = nil;
    NSString *imageCacheKey = nil;
    
    if (self.suggestedImageSize == UserImageViewSizeBig) {
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
        
        UIImage *image = [UIImage imageFromData:imageData withMaxSize:PixelSizeForUserImageSize(self.suggestedImageSize)];

        [self setUserImage:image];
        return;
    }

    @weakify(self);
    
    ImageCacheCompletionBlock completionBlock = ^void(id image, NSString *cacheKey){
        
        @strongify(self);
        
        NSString *updatedCacheKey = nil;
        
        if (self.suggestedImageSize == UserImageViewSizeBig) {
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
        [[UserImageView sharedFullColorImageCacheForSize:self.suggestedImageSize] imageForData:imageData cacheKey:imageCacheKey creationBlock:^id(NSData *data) {
            
            UIImage *image = [UIImage imageFromData:data withMaxSize:PixelSizeForUserImageSize(self.suggestedImageSize)];
            return image;
            
        } completion:completionBlock];
    }
    else {
        [[UserImageView sharedDesaturatedImageCacheForSize:self.suggestedImageSize] imageForData:imageData cacheKey:imageCacheKey creationBlock:^id(NSData *data) {
            
            UIImage *image = [[UserImageView sharedFullColorImageCacheForSize:self.suggestedImageSize] imageForCacheKey:imageCacheKey];
            
            if (! image) {
                image = [UIImage imageFromData:data withMaxSize:PixelSizeForUserImageSize(self.suggestedImageSize)];
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
        self.containerView.backgroundColor = [(id)self.user accentColor];
    }
    else {
        self.containerView.backgroundColor = [UIColor colorWithMagicIdentifier:@"connect.user_not_connected_color"];
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
    if (self.suggestedImageSize == UserImageViewSizeBig) {
        if (change.imageMediumDataChanged || change.connectionStateChanged) {
            [self updateBorderColor];
            [self updateUserImage];
        }
    }
    else {
        if (change.imageSmallProfileDataChanged || change.connectionStateChanged) {
            [self updateBorderColor];
            [self updateUserImage];
        }
    }
    
    if (change.accentColorValueChanged) {
        [self updateBorderColor];
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

@implementation UserImageView (Magic)

- (void)setupWithMagicPrefix:(NSString *)prefix
{
    if (0 < [prefix length]) {
        self.borderWidth = [WAZUIMagic cgFloatForIdentifier:[self magicPathForKey:@"stroke_width" withPrefix:prefix]];
        self.initials.font = [UIFont fontWithMagicIdentifier:[self magicPathForKey:@"user_initials_font" withPrefix:prefix]];
        self.initials.textColor = [UIColor colorWithMagicIdentifier:[self magicPathForKey:@"user_initials_font_color" withPrefix:prefix]];
    }
}

- (NSString *)magicPathForKey:(NSString *)key withPrefix:(NSString *)prefix
{
    return [NSString stringWithFormat:@"%@.%@", prefix, key];
}

@end
