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


#import "MediaPreviewData+Vimeo.h"
#import "MediaThumbnail.h"
@import VIMNetworkingFramework;


@interface MediaThumbnail (Vimeo)
- (instancetype)initWithVimeoThumbnail:(VIMPicture *)vimeoThumbnail;
@end


@implementation MediaPreviewData (Vimeo)

- (instancetype)initWithVimeoVideo:(VIMVideo *)video
{
    NSString *title = video.name;
    NSMutableArray *thumbnails = [NSMutableArray new];
    VIMPictureCollection *vimeoThumbnails = video.pictureCollection;
    if (vimeoThumbnails) {
        for (VIMPicture *vimeoThumbnail in vimeoThumbnails.pictures) {
            MediaThumbnail *thumbnail = [[MediaThumbnail alloc] initWithVimeoThumbnail:vimeoThumbnail];
            if (thumbnail) {
                [thumbnails addObject:thumbnail];
            }
        }
    }
    return [self initWithTitle:title thumbnails:thumbnails provider:MediaPreviewDataProviderVimeo];
}

@end



@implementation  MediaThumbnail (Vimeo)

- (instancetype)initWithVimeoThumbnail:(VIMPicture *)vimeoThumbnail
{
    if (vimeoThumbnail.link) {
        NSURL *url = [NSURL URLWithString:vimeoThumbnail.link];
        CGSize size = CGSizeZero;
        if (vimeoThumbnail.width && vimeoThumbnail.height) {
            size = CGSizeMake(vimeoThumbnail.width.floatValue, vimeoThumbnail.height.floatValue);
        }
        return [self initWithURL:url size:size];
    } else {
        return nil;
    }
}

@end
