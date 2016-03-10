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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import ZMTransport;

#import "ZMUpdateEventsCatchUpPhaseTwoState.h"
#import "ZMMissingUpdateEventsTranscoder.h"
#import "ZMSyncStateMachine.h"
#import "ZMMissingUpdateEventsTranscoder.h"
#import "ZMObjectStrategyDirectory.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUserProfileUpdateTranscoder.h"


@interface ZMUpdateEventsCatchUpPhaseTwoState ()

@property (nonatomic) BOOL errorInDowloading;

@end

@implementation ZMUpdateEventsCatchUpPhaseTwoState

- (ZMUpdateEventsPolicy)updateEventsPolicy
{
    return ZMUpdateEventPolicyBuffer;
}


- (void)didEnterState
{
    self.errorInDowloading = NO;
    [self.objectStrategyDirectory.missingUpdateEventsTranscoder startDownloadingMissingNotifications];
}

- (void)dataDidChange
{
    id<ZMStateMachineDelegate> stateMachine = self.stateMachineDelegate;
    
    if(self.errorInDowloading) {
        self.errorInDowloading = NO;
        [stateMachine startSlowSync];
        return;
    }
    
    const BOOL waitingForNotifications = self.objectStrategyDirectory.missingUpdateEventsTranscoder.isDownloadingMissingNotifications;
    
    if(!waitingForNotifications) {
        [stateMachine goToState:stateMachine.eventProcessingState];
        return;
    }

}

- (ZMTransportRequest *)nextRequest
{
    id<ZMObjectStrategyDirectory> directory = self.objectStrategyDirectory;
    ZMTransportRequest *request = [directory.missingUpdateEventsTranscoder.requestGenerators nextRequest];
    if(request != nil) {
        ZM_WEAK(self);
        [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:directory.moc block:^(ZMTransportResponse *response) {
            ZM_STRONG(self);
            if(response.result == ZMTransportResponseStatusPermanentError) {
                self.errorInDowloading = YES;
            }
        }]];
    }
    else {
        request = [directory.userProfileUpdateTranscoder.requestGenerators nextRequest];
    }
    return request;
}

@end
