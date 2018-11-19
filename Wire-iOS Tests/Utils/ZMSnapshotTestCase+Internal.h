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

static CGSize const ZMDeviceSizeIPhone5 = (CGSize){ .width = 320, .height = 568 };
static CGSize const ZMDeviceSizeIPhone6 = (CGSize){ .width = 375, .height = 667 };
static CGSize const ZMDeviceSizeIPhone6Plus = (CGSize){ .width = 414, .height = 736 };
static CGSize const ZMDeviceSizeIPhoneX = (CGSize){ .width = 375, .height = 812 };
static CGSize const ZMDeviceSizeIPhoneXR = (CGSize){ .width = 414, .height = 896 };

static CGSize const ZMDeviceSizeIPadPortrait = (CGSize){ .width = 768, .height = 1024 };
static CGSize const ZMDeviceSizeIPadLandscape = (CGSize){ .width = 1024, .height = 768 };

static NSArray<NSValue *> * _Nonnull phoneSizes(void) {
    return @[
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone5],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone6],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhone6Plus],
             [NSValue valueWithCGSize:ZMDeviceSizeIPhoneX],
             ///same size as iPhone Xs Max
             [NSValue valueWithCGSize:ZMDeviceSizeIPhoneXR]
             ];
}

static NSArray<NSValue *> * _Nonnull tabletSizes(void) {
    return @[
             [NSValue valueWithCGSize:ZMDeviceSizeIPadPortrait],
             [NSValue valueWithCGSize:ZMDeviceSizeIPadLandscape]
             ];
}
