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


#import "UserBackgroundView.h"
#import "zmessaging+iOS.h"
#import "UIColor+WAZExtensions.h"


@interface UserBackgroundView () <ZMUserObserver>

@property (nonatomic) id userObserverToken;

@end


@implementation UserBackgroundView


- (void)setUser:(id<ZMBareUser>)user
{
    [self setUser:user animated:YES waitForBlur:YES];
}

- (void)setUser:(id<ZMBareUser>)user animated:(BOOL)animated waitForBlur:(BOOL)waitForBlur
{
    if (! user) {
        DDLogInfo(@"Setting nil user on background");
        
        return;
    }
    if ([user isEqual:_user]) {
        return;
    }
    
    _user = user;

    if ([user isKindOfClass:[ZMUser class]] || [user isKindOfClass:[ZMSearchUser class]]) {
        self.userObserverToken = [UserChangeInfo addObserver:self forBareUser:user];
    }
    
    if (user.imageMediumData == nil) {
        if ([user isKindOfClass:[ZMSearchUser class]]) {
            ZMSearchUser *searchUser = (ZMSearchUser *)user;
            if (searchUser.imageMediumData == nil) {
                [searchUser requestMediumProfileImageInUserSession:[ZMUserSession sharedSession]];
            }
        }
        [self setFlatColor:[ZMUser selfUser].accentColor];
    }
    else {        
        [self setImageData:user.imageMediumData withCacheKey:user.imageMediumIdentifier animated:animated waitForBlur:waitForBlur];
    }
}

- (void)userDidChange:(UserChangeInfo *)change
{
    if (change.imageMediumDataChanged && change.user.imageMediumData != nil) {
        [self setImageData:change.user.imageMediumData withCacheKey:change.user.imageMediumIdentifier animated:YES waitForBlur:self.waitForBlur forceUpdate:YES];
    }
    else if ( (change.imageMediumDataChanged && change.user.imageMediumData == nil ) ||
              (change.accentColorValueChanged && change.user.imageMediumData == nil) ) {
        [self setFlatColor:[UIColor colorForZMAccentColor:change.user.accentColorValue]];
    }
}

@end
