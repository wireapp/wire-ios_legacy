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


#import "AnalyticsDecryptionFailedObserver.h"
@import WireSyncEngine;

#import "Analytics+OTREvents.h"


@interface AnalyticsDecryptionFailedObserver ()

@property (weak, nonatomic) Analytics *analytics;

@end

@implementation AnalyticsDecryptionFailedObserver

- (instancetype)initWithAnalytics:(Analytics *)analytics;
{
    self = [super init];
    if (self) {
        _analytics = analytics;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(messageCannotBeDecrypted:)
                                                     name:[ZMConversation failedToDecryptMessageNotificationName]
                                                   object:nil];
    }
    return self;
}

- (void)messageCannotBeDecrypted:(NSNotification *)note;
{
    NSMutableDictionary* trackingInfo = [[NSMutableDictionary alloc] init];
    if (nil != note.userInfo[@"deviceClass"]) {
        trackingInfo[@"deviceClass"] = note.userInfo[@"deviceClass"];
    }
    if (nil != note.userInfo[@"cause"]) {
        trackingInfo[@"cause"] = note.userInfo[@"cause"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.analytics tagCannotDecryptMessageWithAttributes:trackingInfo];
    });
}

@end
