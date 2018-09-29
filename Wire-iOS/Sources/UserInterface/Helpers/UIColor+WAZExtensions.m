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


#import "UIColor+WAZExtensions.h"

#import "WireSyncEngine+iOS.h"
#import "ColorScheme.h"
#import "Wire-Swift.h"

@import WireExtensionComponents;

static NSString* ZMLogTag ZM_UNUSED = @"UI";
static ZMAccentColor overridenAccentColor = ZMAccentColorUndefined;

@implementation UIColor (WAZExtensions)

+ (void)setAccentColor:(ZMAccentColor)accentColor
{
    id<ZMEditableUser> editableSelf = [ZMUser editableSelfUser];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        editableSelf.accentColorValue = accentColor;
    }];
}

+ (ZMAccentColor)indexedAccentColor
{
	// priority 1: overriden color
	if (overridenAccentColor != ZMAccentColorUndefined) {
		return overridenAccentColor;
	}
	
	// priority 2: color from self user
	ZMUser *selfUser = [ZMUser selfUserInUserSession:[SessionManager shared].activeUserSession];
	ZMAccentColor selfAccentColor = selfUser.accentColorValue;
	if (selfUser && (selfAccentColor != ZMAccentColorUndefined)) {
		return selfAccentColor;
	}
	
	// priority 3: default color
	return ZMAccentColorStrongBlue;
}

+ (UIColor *)colorForZMAccentColor:(ZMAccentColor)accentColor
{
	if (accentColor == ZMAccentColorUndefined) {
        return nil;
    }
    
    NSArray *accentColors = @[[UIColor colorWithRed:0.141 green:0.552 blue:0.827 alpha:1],
                              [UIColor colorWithRed:0     green:0.784 blue:0     alpha:1],
                              [UIColor colorWithRed:0.996 green:0.749 blue:0.007 alpha:1],
                              [UIColor colorWithRed:1     green:0.152 blue:0     alpha:1],
                              [UIColor colorWithRed:1     green:0.537 blue:0     alpha:1],
                              [UIColor colorWithRed:0.996 green:0.368 blue:0.741 alpha:1],
                              [UIColor colorWithRed:0.615 green:0     blue:1     alpha:1]];
        
    if (accentColor < 1 || accentColor > (NSInteger)accentColors.count) {
        ZMLogError(@"Accent color index is out of bounds: %d", accentColor);
        return accentColors[0];
    }
    
    NSUInteger colorIndex = accentColor - 1;
    colorIndex = MIN(accentColors.count - 1, colorIndex);
    colorIndex = MAX(0u, colorIndex);
    return accentColors[colorIndex];
}

+ (void)setAccentOverrideColor:(ZMAccentColor)overrideColor
{
    if (overridenAccentColor == overrideColor) {
        return;
    }
    
    overridenAccentColor = overrideColor;
}

- (BOOL)isEqualTo:(id)object;
{
    if (! [object isKindOfClass:[UIColor class]]) {
        return NO;
    }
    UIColor *lhs = self;
    UIColor *rhs = object;

    CGFloat rgba1[4];
    [lhs getRed:rgba1 + 0 green:rgba1 + 1 blue:rgba1 + 2 alpha:rgba1 + 3];
    CGFloat rgba2[4];
    [rhs getRed:rgba2 + 0 green:rgba2 + 1 blue:rgba2 + 2 alpha:rgba2 + 3];

    return ((rgba1[0] == rgba2[0]) &&
            (rgba1[1] == rgba2[1]) &&
            (rgba1[2] == rgba2[2]) &&
            (rgba1[3] == rgba2[3]));
}

@end
