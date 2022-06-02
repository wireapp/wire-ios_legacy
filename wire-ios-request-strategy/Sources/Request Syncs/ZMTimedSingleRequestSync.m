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


@import WireSystem;
@import WireDataModel;

#import <WireRequestStrategy/WireRequestStrategy-Swift.h>

#import "ZMTimedSingleRequestSync.h"

@class ZMTimedRequestTriggerHolder;

@interface ZMTimedSingleRequestSync ()

@property (nonatomic) ZMTransportRequest *internalRequest;
@property (nonatomic) NSTimeInterval internalTimeInterval;
@property (atomic) BOOL shouldReturnRequest;
@property (nonatomic) ZMTimedRequestTriggerHolder *currentHolder;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) BOOL isInvalidated;

- (void)timerDidExpire;

@end


@interface ZMTimedRequestTriggerHolder : NSObject

@property (nonatomic, weak) ZMTimedSingleRequestSync *triggerReference;

- (instancetype)initWithTimedSingleRequest:(ZMTimedSingleRequestSync *)timedSingleRequest;

- (void)invalidate;
- (void)fireTrigger;

@end

@implementation ZMTimedRequestTriggerHolder

- (instancetype)initWithTimedSingleRequest:(ZMTimedSingleRequestSync *)timedSingleRequest;
{
    self = [super init];
    if(self) {
        self.triggerReference = timedSingleRequest;
    }
    return self;
}

- (void)invalidate
{
    self.triggerReference = nil;
}

- (void)fireTrigger
{
    [self.triggerReference timerDidExpire];
}

@end



@implementation ZMTimedSingleRequestSync

- (instancetype)initWithSingleRequestTranscoder:(id<ZMSingleRequestTranscoder>)transcoder
              everyTimeInterval:(NSTimeInterval) timeInterval
                     groupQueue:(id<ZMSGroupQueue>)groupQueue
{
    self = [super initWithSingleRequestTranscoder:transcoder groupQueue:(id<ZMSGroupQueue>)groupQueue];
    if(self) {
        self.timeInterval = timeInterval;
        self.shouldReturnRequest = YES;
        self.queue = dispatch_queue_create("ZMTimedSingleRequestSync", DISPATCH_QUEUE_SERIAL);
        [self readyForNextRequest];
    }
    return self;
}

- (void)dealloc
{
    RequireString(self.isInvalidated, "Did not invalidate timer before dealloc");
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    if(self.shouldReturnRequest && ( ! self.isInvalidated) ) {
        
        [self.currentHolder invalidate];
        
        if(self.timeInterval > 0) {
            
            self.shouldReturnRequest = NO;
            ZMTimedRequestTriggerHolder *holder = [[ZMTimedRequestTriggerHolder alloc] initWithTimedSingleRequest:self];
            self.currentHolder = holder;
            
            ZMSDispatchGroup * group = self.groupQueue.dispatchGroup;
            [group enter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeInterval * NSEC_PER_SEC)), self.queue, ^{
                [holder fireTrigger];
                [group leave];
            });
        }
        
        return [super nextRequestForAPIVersion:apiVersion];
    }
    return nil;
}

- (void)timerDidExpire
{
    [self.groupQueue performGroupedBlock:^{
        self.currentHolder = nil;
        self.shouldReturnRequest = YES;
        [self readyForNextRequest];
        [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];
    }];
}

- (void)invalidate
{
    ZMSDispatchGroup * group = self.groupQueue.dispatchGroup;
    [group enter];
    dispatch_sync(self.queue, ^{
        [self.currentHolder invalidate];
    });
    [group leave];
    self.shouldReturnRequest = NO;
    self.isInvalidated = YES;
}

- (NSTimeInterval)timeInterval
{
    return self.internalTimeInterval;
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval
{
    [self.currentHolder invalidate];
    self.internalTimeInterval = timeInterval;
    self.shouldReturnRequest = YES;
    [self readyForNextRequest];
}

@end
