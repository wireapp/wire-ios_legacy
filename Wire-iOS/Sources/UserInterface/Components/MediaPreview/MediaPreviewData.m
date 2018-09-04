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


#import "MediaPreviewData.h"
#import "MediaThumbnail.h"

@implementation MediaPreviewData

- (instancetype)initWithTitle:(NSString *)title thumbnails:(NSArray<MediaThumbnail *> *)thumbnails provider:(MediaPreviewDataProvider)provider
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _thumbnails = thumbnails;
        _provider = provider;
    }
    return self;
}

/// Returns thumbnail with most suitable size for current platform:
/// takes thumbnail with closest size.
- (MediaThumbnail *)bestThumbnailForSize:(CGSize)size
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    CGSize targetSize = CGSizeApplyAffineTransform(size, transform);
    
    if (self.thumbnails) {
        
        // metric is being closer to target size width
        NSArray *sortedThumbnails = [self.thumbnails sortedArrayUsingComparator:^NSComparisonResult(MediaThumbnail *obj1, MediaThumbnail *obj2) {
            CGFloat distance1 = fabs(obj1.size.width - targetSize.width);
            CGFloat distance2 = fabs(obj2.size.width - targetSize.width);
            if (distance1 < distance2) {
                return NSOrderedAscending;
            } else if (distance1 > distance2) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
        return sortedThumbnails.firstObject;
    } else {
        return nil;
    }
}

@end
