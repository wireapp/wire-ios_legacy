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

#import "ColorScheme.h"
#import "Wire-Swift.h"



static NSString* ZMLogTag ZM_UNUSED = @"UI";
static ZMAccentColor overridenAccentColor = ZMAccentColorUndefined;

@implementation UIColor (WAZExtensions)

+ (void)setAccentColor:(ZMAccentColor)accentColor
{
    id<ZMEditableUser> editableSelf = [ZMUser selfUser];
    [[ZMUserSession sharedSession] enqueueChanges:^{
        editableSelf.accentColorValue = accentColor;
    }];
}

+ (ZMAccentColor)accentOverrideColor {
    id<ZMEditableUser> editableSelf = [ZMUser selfUser];

    return editableSelf.accentColorValue;
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
