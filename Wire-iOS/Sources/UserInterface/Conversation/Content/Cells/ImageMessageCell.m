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


@import MobileCoreServices;

#import "ImageMessageCell+Internal.h"
#import <PureLayout/PureLayout.h>
#import <zmessaging/zmessaging.h>

#import "Constants.h"
#import "WAZUIMagic.h"
#import "UIColor+MagicAccess.h"
#import "UIColor+WAZExtensions.h"
#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import "ImageCache.h"
#import "UIImage+ImageUtilities.h"
#import "MediaAsset.h"
#import "Analytics+iOS.h"
#import "Wire-Swift.h"

#import "UIView+Borders.h"



@interface Message (DataIdentifier)

+ (NSString *)nonNilImageDataIdentifier:(id<ZMConversationMessage>)message;

@end



@implementation Message (DataIdentifier)

+ (NSString *)nonNilImageDataIdentifier:(id<ZMConversationMessage>)message
{
    NSString *identifier = message.imageMessageData.imageDataIdentifier;
    if (! identifier) {
        DDLogWarn(@"Image cache key is nil!");
        return [NSString stringWithFormat:@"nonnil-%p", message.imageMessageData.imageData];
    }
    return identifier;
}

@end

@protocol MediaAsset;

@interface ImageMessageCell ()

@property (nonatomic, strong) FLAnimatedImageView *fullImageView;
@property (nonatomic, strong) ThreeDotsLoadingView *loadingView;
@property (nonatomic, strong) IconButton *sketchButton;
@property (nonatomic, strong) IconButton *fullScreenButton;
@property (nonatomic, strong) UIView *imageViewContainer;
@property (nonatomic) UIEdgeInsets defaultLayoutMargins;

/// Can either be UIImage or FLAnimatedImage
@property (nonatomic, strong) id<MediaAsset> image;

@property (nonatomic, strong) NSLayoutConstraint *imageWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *imageAspectConstraint;
@property (nonatomic, strong) NSLayoutConstraint *imageTopInsetConstraint;

@property (nonatomic, assign) CGSize originalImageSize;

@end

@implementation ImageMessageCell

static ImageCache *imageCache(void)
{
    static ImageCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[ImageCache alloc] initWithName:@"ConversationImageTableCell.imageCache"];
        cache.maxConcurrentOperationCount = 4;
        cache.totalCostLimit = 1024 * 1024 * 10; // 10 MB
        cache.qualityOfService = NSQualityOfServiceUtility;
    });
    return cache;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self createImageMessageViews];
        [self createConstraints];
        
        self.defaultLayoutMargins = UIEdgeInsetsMake(0, [WAZUIMagic floatForIdentifier:@"content.left_margin"],
                                                     0, [WAZUIMagic floatForIdentifier:@"content.right_margin"]);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:[UIApplication sharedApplication]];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:[UIApplication sharedApplication]];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    FLAnimatedImage *image = self.fullImageView.animatedImage;
    if (image) {
        image.frameCacheSizeMax = 1;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    FLAnimatedImage *image = self.fullImageView.animatedImage;
    if (image) {
        image.frameCacheSizeMax = 0; // not limited
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.originalImageSize = CGSizeZero;
    
    self.image = nil;

    if (self.imageAspectConstraint) {
        [self.imageViewContainer removeConstraint:self.imageAspectConstraint];
        self.imageAspectConstraint = nil;
    }
    
}

- (void)didEndDisplayingInTableView
{
    [super didEndDisplayingInTableView];
    
    [self recycleImage];
}

- (void)createImageMessageViews
{
    self.imageViewContainer = [[UIView alloc] init];
    self.imageViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.messageContentView addSubview:self.imageViewContainer];
        
    self.fullImageView = [[FLAnimatedImageView alloc] init];
    self.fullImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.fullImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.fullImageView.clipsToBounds = YES;
    [self.imageViewContainer addSubview:self.fullImageView];

    self.loadingView = [[ThreeDotsLoadingView alloc] initForAutoLayout];
    [self.imageViewContainer addSubview:self.loadingView];
  
    self.accessibilityIdentifier = @"ImageCell";
    
    self.loadingView.hidden = NO;
    
    self.sketchButton = [IconButton iconButtonCircularLight];
    [self.sketchButton addTarget:self action:@selector(onSketchPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.sketchButton setIcon:ZetaIconTypeBrush withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.sketchButton setBackgroundImageColor:[[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorBackground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    self.sketchButton.alpha = self.selected ? 1 : 0;
    [self.imageViewContainer addSubview:self.sketchButton];
    
    self.fullScreenButton = [IconButton iconButtonCircularLight];
    [self.fullScreenButton addTarget:self action:@selector(onFullScreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenButton setIcon:ZetaIconTypeFullScreen withSize:ZetaIconSizeTiny forState:UIControlStateNormal];
    [self.fullScreenButton setBackgroundImageColor:[[ColorScheme defaultColorScheme] colorWithName:ColorSchemeColorBackground variant:ColorSchemeVariantDark] forState:UIControlStateNormal];
    self.fullScreenButton.alpha = self.selected ? 1 : 0;
    [self.imageViewContainer addSubview:self.fullScreenButton];
}

- (void)createConstraints
{
    [self.fullImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.loadingView autoCenterInSuperview];

    self.imageTopInsetConstraint = [self.imageViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.imageViewContainer autoPinEdgeToSuperviewMargin:ALEdgeRight relation:NSLayoutRelationGreaterThanOrEqual];
    [self.imageViewContainer autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    
    [NSLayoutConstraint autoSetPriority:ALLayoutPriorityDefaultHigh + 1 forConstraints:^{
        [self.imageViewContainer autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        self.imageWidthConstraint = [self.imageViewContainer autoSetDimension:ALDimensionWidth toSize:0];
    }];
    
    [self.sketchButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16];
    [self.sketchButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16];
    [self.sketchButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
    
    [self.fullScreenButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
    [self.fullScreenButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:16];
    [self.fullScreenButton autoSetDimensionsToSize:CGSizeMake(32, 32)];
}

 - (void)updateImageMessageConstraintConstants
{
    self.imageTopInsetConstraint.constant = self.layoutProperties.showSender ? 12 : 0;
    
    if (! CGSizeEqualToSize(self.originalImageSize, CGSizeZero)) {
        
        CGRect screen = UIScreen.mainScreen.bounds;
        CGFloat screenRatio = CGRectGetHeight(screen) / CGRectGetWidth(screen);
        CGFloat imageRatio = self.originalImageSize.height / self.originalImageSize.width;
        CGFloat lowerBound = screenRatio * 0.84, upperBound = screenRatio * 1.2;
        
        BOOL imageWidthExceedsBounds = self.originalImageSize.width > self.bounds.size.width;
        BOOL similarRatio = lowerBound < imageRatio && imageRatio < upperBound;
        BOOL displayEdgeToEdge = imageWidthExceedsBounds && !similarRatio;
        
        self.messageContentView.layoutMargins = displayEdgeToEdge ? UIEdgeInsetsZero : self.defaultLayoutMargins;
        self.imageWidthConstraint.constant = self.originalImageSize.width;
        
        if (! self.imageAspectConstraint) {
            CGFloat aspectRatio = self.originalImageSize.height / self.originalImageSize.width;
            [NSLayoutConstraint autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
                self.imageAspectConstraint = [self.imageViewContainer autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imageViewContainer withMultiplier:aspectRatio];
            }];
        }
    }
}

- (void)configureForMessage:(id<ZMConversationMessage>)convMessage layoutProperties:(ConversationCellLayoutProperties *)layoutProperties
{
    if (! [Message isImageMessage:convMessage]) {
        return;
    }
    id<ZMImageMessageData> imageMessageData = convMessage.imageMessageData;
    
    // request
    [convMessage requestImageDownload]; // there is no harm in calling this if the full content is already available
    
    [super configureForMessage:convMessage layoutProperties:layoutProperties];
    
    self.originalImageSize = imageMessageData.originalSize;
    
    [self updateImageMessageConstraintConstants];
    
    NSData *imageData = imageMessageData.imageData;
    
    // If medium image is present, use the medium image
    if (imageData.length > 0) {
        
        BOOL isAnimatedGIF = imageMessageData.isAnimatedGIF;
        
        @weakify (self)
        [imageCache() imageForData:imageData cacheKey:[Message nonNilImageDataIdentifier:convMessage] creationBlock:^id(NSData *data) {
            
            id image = nil;
            
            if (isAnimatedGIF) {
                // We MUST make a copy of the data here because FLAnimatedImage doesn't read coredata blobs efficiently
                NSData *copy = [NSData dataWithBytes:data.bytes length:data.length];
                image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:copy];
            } else {
                
                CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
                CGFloat widthRatio = MIN(screenSize.width / self.originalImageSize.width, 1.0);
                CGFloat minimumHeight = self.originalImageSize.height * widthRatio;
                CGFloat maxSize = MAX(screenSize.width, minimumHeight);
                
                image = [UIImage imageFromData:data withMaxSize:maxSize];
            }
            
            if (image == nil) {
                DDLogError(@"Invalid image data returned from sync engine!");
            }
            return image;
            
        } completion:^(id image, NSString *cacheKey) {
            @strongify(self);
            
            // Double check that our cell's current image is still the same one
            if (image != nil && self.message != nil && cacheKey != nil && [cacheKey isEqualToString: [Message nonNilImageDataIdentifier:self.message]]) {
                self.image = image;
            }
            else {
                DDLogInfo(@"finished loading image but cell is no longer on screen.");
            }
        }];
    }
    else {
        // We did not download the medium image yet, start the progress animation
        [self.loadingView startProgressAnimation];
        self.loadingView.hidden = NO;
    }
}

- (void)setImage:(id<MediaAsset>)image
{
    if (_image == image) {
        return;
    }
    _image = image;
    if (image != nil) {
        self.loadingView.hidden = YES;
        [self.loadingView stopProgressAnimation];
        [self.fullImageView setMediaAsset:image];
        [self showImageView:self.fullImageView];
    } else {
        [self.fullImageView setMediaAsset:nil];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    dispatch_block_t changeBlock = ^{
        self.sketchButton.alpha = self.selected ? 1 : 0;
        self.fullScreenButton.alpha = self.selected ? 1 : 0;
    };
    
    if (animated) {
        [UIView animateWithDuration:0.15 animations:changeBlock completion:nil];
    }
    else {
        changeBlock();
    }
    
}

- (void)showImageView:(UIView *)imageView
{
    self.fullImageView.hidden = imageView != self.fullImageView;
}

- (void)recycleImage
{
    self.image = nil;
}

#pragma mark - Actions

- (void)onFullScreenPressed:(id)sender {
    [self.delegate conversationCell:self didSelectAction:ConversationCellActionPresent];
}

- (void)onSketchPressed:(id)sender {
    [self.delegate conversationCell:self didSelectAction:ConversationCellActionSketch];
}

#pragma mark - Message updates

/// Overriden from the super class cell
- (BOOL)updateForMessage:(MessageChangeInfo *)change
{
    BOOL needsLayout = [super updateForMessage:change];
    
    if (change.imageChanged) {
        [self configureForMessage:self.message layoutProperties:self.layoutProperties];
    }
    
    return needsLayout;
}

#pragma mark - Copy/Paste

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action
              withSender:(id)sender
{
    
    if (action == @selector(cut:)) {
        return NO;
    }
    else if (action == @selector(copy:)) {
        return self.fullImageView.image != nil;
    }
    else if (action == @selector(paste:)) {
        return NO;
    }
    else if (action == @selector(select:) || action == @selector(selectAll:)) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender
{
    [[Analytics shared] tagOpenedMessageAction:MessageActionTypeCopy];
    [[Analytics shared] tagMessageCopy];

    [[UIPasteboard generalPasteboard] setMediaAsset:[self.fullImageView mediaAsset]];
}

- (void)setSelectedByMenu:(BOOL)selected animated:(BOOL)animated
{
    DDLogDebug(@"Setting selected: %@ animated: %@", @(selected), @(animated));
    
    dispatch_block_t animations = ^{
        self.fullImageView.alpha = selected ? ConversationCellSelectedOpacity : 1.0f;
    };
    
    if (animated) {
        [UIView animateWithDuration:ConversationCellSelectionAnimationDuration animations:animations];
    } else {
        animations();
    }
}

- (CGRect)selectionRect
{
    return self.imageViewContainer.bounds;
}

- (UIView *)selectionView
{
    return self.imageViewContainer;
}

- (MenuConfigurationProperties *)menuConfigurationProperties;
{
    MenuConfigurationProperties *properties = [[MenuConfigurationProperties alloc] init];
    properties.targetRect = self.selectionRect;
    properties.targetView = self.selectionView;
    properties.selectedMenuBlock = ^(BOOL selected, BOOL animated) {
        [self setSelectedByMenu:selected animated:animated];
    };
    return properties;
}

- (MessageType)messageType;
{
    return MessageTypeImage;
}

@end
