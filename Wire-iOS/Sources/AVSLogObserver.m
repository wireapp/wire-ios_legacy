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


#import "AVSLogObserver.h"
#import "WireSyncEngine+iOS.h"

@interface AVSLogObserver () <ZMAVSLogObserver>
@property (nonatomic, strong) id<ZMAVSLogObserverToken> token;
@end

@implementation AVSLogObserver

- (void)dealloc
{
    [ZMUserSession removeAVSLogObserver:self.token];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.token = [ZMUserSession addAVSLogObserver:self];
    }
    return self;
}

// MARK: - ZMAVSLogObserver

- (void)logMessage:(NSString *)msg
{
    DDLogVoice(@"AVS: %@", msg);
}

@end
