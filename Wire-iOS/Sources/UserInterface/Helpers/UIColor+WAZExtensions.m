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

#import "WAZUIMagiciOS.h"
#import "WireSyncEngine+iOS.h"
#import "CASStyler+Variables.h"
#import "ColorScheme.h"
#import "Wire-Swift.h"

@import WireExtensionComponents;

static ZMAccentColor overridenAccentColor = ZMAccentColorUndefined;



@implementation UIColor (WAZExtensions)

+ (instancetype)accentColor
{
	return [self colorForZMAccentColor:[self indexedAccentColor]];
}

+ (ZMAccentColor)indexedAccentColor
{
	// priority 1: overriden color
	if (overridenAccentColor != ZMAccentColorUndefined) {
		return overridenAccentColor;
	}
	
	// priority 2: color from self user
	ZMUser *selfUser = [SessionManager shared].currentUser;
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
		
    NSArray *accentColors = [UIColor colorArrayWithMagicIdentifier:@"accent_colors"];
    
    if (accentColors.count == 0) {
        return nil;
    }
    
    if (accentColor < 1 || accentColor > (NSInteger)accentColors.count) {
        DDLogError(@"Accent color index is out of bounds: %d", accentColor);
        return accentColors[0];
    }
    
    NSUInteger colorIndex = accentColor - 1;
    colorIndex = MIN(accentColors.count - 1, colorIndex);
    colorIndex = MAX(0u, colorIndex);
    return accentColors[colorIndex];
}

+ (void)setAccentColor:(ZMAccentColor)accentColor
{
	id<ZMEditableUser> editableSelf = [ZMUser editableSelfUser];
	[[ZMUserSession sharedSession] enqueueChanges:^{
		editableSelf.accentColorValue = accentColor;
	}];
}

+ (void)setAccentOverrideColor:(ZMAccentColor)overrideColor
{
    if (overridenAccentColor == overrideColor) {
        return;
    }
    
    overridenAccentColor = overrideColor;
    
    [[CASStyler defaultStyler] applyDefaultColorSchemeWithAccentColor:[self accentColor]];
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
