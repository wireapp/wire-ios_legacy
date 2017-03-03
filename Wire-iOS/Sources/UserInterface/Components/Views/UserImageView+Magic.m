//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


#import "UserImageView+Magic.h"
#import "UIFont+MagicAccess.h"
#import "UIColor+MagicAccess.h"

@implementation UserImageView (Magic)

- (instancetype)initWithMagicPrefix:(NSString *)magicPrefix
{
    self = [self initWithFrame:CGRectZero];
    
    if (self) {
        [self setupWithMagicPrefix:magicPrefix];
    }
    
    return self;
}

- (void)setupWithMagicPrefix:(NSString *)prefix
{
    if (0 < [prefix length]) {
        self.initials.font = [UIFont fontWithMagicIdentifier:[self magicPathForKey:@"user_initials_font" withPrefix:prefix]];
        self.initials.textColor = [UIColor colorWithMagicIdentifier:[self magicPathForKey:@"user_initials_font_color" withPrefix:prefix]];
    }
}

- (NSString *)magicPathForKey:(NSString *)key withPrefix:(NSString *)prefix
{
    return [NSString stringWithFormat:@"%@.%@", prefix, key];
}

@end
