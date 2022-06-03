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


#import "ZMImageOwner.h"

ZMImageFormat ImageFormatFromString(NSString *string)
{
    if ([string isEqualToString:@"preview"]) {
        return ZMImageFormatPreview;
    }
    if ([string isEqualToString:@"medium"]) {
        return ZMImageFormatMedium;
    }
    if ([string isEqualToString:@"smallProfile"]) {
        return ZMImageFormatProfile;
    }
    if([string isEqualToString:@"original"]) {
        return ZMImageFormatOriginal;
    }
    return ZMImageFormatInvalid;
}

NSString * StringFromImageFormat(ZMImageFormat format)
{
    switch (format) {
        case ZMImageFormatProfile:
            return @"smallProfile";

        case ZMImageFormatMedium:
            return @"medium";

        case ZMImageFormatPreview:
            return @"preview";

        case ZMImageFormatInvalid:
            return @"invalid";
            
        case ZMImageFormatOriginal:
            return @"original";
    }
}
