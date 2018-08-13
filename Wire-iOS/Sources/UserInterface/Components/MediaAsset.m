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


#import "MediaAsset.h"


#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Wire-Swift.h"

@implementation FLAnimatedImage(MediaAsset)

- (BOOL)isGIF
{
    return YES;
}

- (BOOL)isTransparent
{
    return NO;
}

@end



@implementation UIImageView(MediaAssetView)

- (NSData *)imageData
{
    return self.image.data;
}

- (void)setImageData:(NSData *)imageData
{
    self.image = [[UIImage alloc] initWithData:imageData];
}

+ (instancetype)imageViewWithMediaAsset:(id<MediaAsset>)image;
{
    if ([image isGIF]) {
        FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
        animatedImageView.animatedImage = image;
        return animatedImageView;
    }
    else {
        return [[UIImageView alloc] initWithImage:[(UIImage *)image downsizedImage]];
    }
}

- (id<MediaAsset>)mediaAsset
{
    return self.image;
}

- (void)setMediaAsset:(id<MediaAsset>)image
{
    if (image == nil) {
        self.image = nil;
    }
    else if (![image isGIF]) {
        self.image = [(UIImage *)image downsizedImage];
    }
}

@end



@implementation FLAnimatedImageView(MediaAssetView)

- (id<MediaAsset>)mediaAsset
{
    return self.animatedImage ?: self.image;
}

- (void)setMediaAsset:(id<MediaAsset>)image
{
    if (image == nil) {
        self.image = nil;
        self.animatedImage = nil;
    }
    else {
        if ([image isGIF]) {
            self.animatedImage = image;
        }
        else {
            self.image = [(UIImage *)image downsizedImage];
        }
    }
}

@end
