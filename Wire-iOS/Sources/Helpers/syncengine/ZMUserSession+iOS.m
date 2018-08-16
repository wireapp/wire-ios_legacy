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


#import "ZMUserSession+iOS.h"
#import "AppDelegate.h"
#import "Wire-Swift.h"

const static unsigned long long MaxFileSize = 25 * 1024 * 1024; // 25 megabytes
const static unsigned long long MaxTeamFileSize = 100 * 1024 * 1024; // 100 megabytes
const static NSTimeInterval MaxAudioLength = 25 * 60.0f; // 25 minutes
const static NSTimeInterval MaxTeamAudioLength = 100 * 60.0f; // 100 minutes
const static NSTimeInterval MaxVideoLength = 4.0f * 60.0f; // 4 minutes
const static NSTimeInterval MaxTeamVideoLength = 16.0f * 60.0f; // 16 minutes

@implementation ZMUserSession (iOS)

+ (instancetype)sharedSession
{
    return [[SessionManager shared] activeUserSession];
}

- (unsigned long long)maxUploadFileSize
{
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self];
    if (selfUser.hasTeam) {
        return MaxTeamFileSize;
    } else {
        return MaxFileSize;
    }
}

- (NSTimeInterval)maxAudioLength
{
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self];
    if (selfUser.hasTeam) {
        return MaxTeamAudioLength;
    } else {
        return MaxAudioLength;
    }
}

- (NSTimeInterval)maxVideoLength
{
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self];
    if (selfUser.hasTeam) {
        return MaxTeamVideoLength;
    } else {
        return MaxVideoLength;
    }
}

@end
