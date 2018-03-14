//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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


#import "UIPasteboard+Compatibility.h"

@implementation UIPasteboard (Compatibility)

- (BOOL)wr_hasImages {
    if(@available(iOS 10, *)) {
        return self.hasImages;
    } else {
        return [self containsPasteboardTypes:UIPasteboardTypeListImage];
    }
}

- (BOOL)wr_hasStrings {
    if(@available(iOS 10, *)) {
        return self.hasStrings;
    } else {
        return [self containsPasteboardTypes:UIPasteboardTypeListString];
    }
}

- (BOOL)wr_hasURLs {
    if(@available(iOS 10, *)) {
        return self.hasURLs;
    } else {
        return [self containsPasteboardTypes:UIPasteboardTypeListURL];
    }
}

@end
