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


#import "Fakes.h"


@implementation FakeDataTask

- (instancetype)initWithError:(NSError *)error taskIdentifier:(NSUInteger)taskIdentifier response:(FakeURLResponse *)response
{
    self = [super init];
    if(self) {
        self.fakeError = error;
        self.fakeTaskIdentifier = taskIdentifier;
        self.fakeURLResponse = response;
    }
    return self;
}

- (NSError *)error
{
    return self.fakeError;
}

- (NSUInteger)taskIdentifier
{
    return self.fakeTaskIdentifier;
}

- (NSURLResponse *)response
{
    return (NSURLResponse *)self.fakeURLResponse;
}

- (void)resume
{
}

- (NSURLRequest *)originalRequest
{
    return nil;
}

@end


@implementation FakeURLResponse

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.body = [NSData data];
        self.allHeaderFields = @{@"Content-Type": @"application/json"};
        self.error = nil;
    }
    
    return self;
}

+ (instancetype)testResponse
{
    return [[self alloc] init];
}

- (void)setBodyFromTransportData:(id<ZMTransportData>)object;
{
    if (object == nil) {
        self.body = nil;
    } else {
        NSError *error = nil;
        self.body = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
        RequireString(self.body != nil, "Failed to serialize JSON: %lu", (long) error.code);
    }
}

- (void)setError:(NSError *)error;
{
    CheckString(error == nil || [error.domain isEqualToString:NSURLErrorDomain],
                "At this API level errors are supposed to be 'NSURLErrorDomain'.");
    _error = error;
}

- (ZMTransportResponseContentType)zmContentTypeForBodyData:(NSData *)bodyData;
{
    (void)bodyData;
    return ZMTransportResponseContentTypeJSON;
}

@end




@implementation FakeTransportResponse

+ (instancetype)testResponse
{
    return [[self alloc] init];
}

@end


@implementation FakeExponentialBackoff

- (instancetype)init;
{
    self = [super init];
    if (self) {
        self.blocks = [NSMutableArray array];
    }
    return self;
}

- (void)performBlock:(dispatch_block_t)block;
{
    [self.blocks addObject:[block copy]];
}

- (void)resetBackoff;
{
    ++self.resetBackoffCount;
}

- (void)increaseBackoff;
{
    ++self.increaseBackoffCount;
}

- (void)tearDown
{
    
}
@end


@implementation FakeDelegate

- (void)handlerDidReceiveAccessToken:(id)sender
{
    (void)sender;
    self.delegateCallCount++;
    
    if (self.didReceiveAccessTokenBlock) {
        self.didReceiveAccessTokenBlock();
    }
}

- (void)handlerDidClearAccessToken:(ZMAccessTokenHandler * __unused)handler
{
    // TODO
}

@end


@implementation FakeGroupQueue

- (void)performGroupedBlock:(dispatch_block_t)block
{
    block();
}

- (ZMSDispatchGroup *)dispatchGroup
{
    return nil;
}

@end


@implementation FakeSchedulerSession

- (void)sendAccessTokenRequest;
{
    ++self.accessTokenRequestCount;
}

- (void)sendSchedulerItem:(id<ZMTransportRequestSchedulerItem>)item;
{
    if (self.sentItems == nil) {
        self.sentItems = [NSMutableArray arrayWithObject:item];
    } else {
        [self.sentItems addObject:item];
    }
}

- (void)temporarilyRejectSchedulerItem:(id<ZMTransportRequestSchedulerItem>)item;
{
    if (self.rejectedItems == nil) {
        self.rejectedItems = [NSMutableArray arrayWithObject:item];
    } else {
        [self.rejectedItems addObject:item];
    }
}

- (void)schedulerIncreasedMaximumNumberOfConcurrentRequests:(ZMTransportRequestScheduler *)scheduler;
{
    NOT_USED(scheduler);
    ++self.maximumNumberOfConcurrentRequestsChangeCount;
}

- (void)schedulerWentOffline:(ZMTransportRequestScheduler *)scheduler
{
    NOT_USED(scheduler);
    ++self.offlineCount;
}

@end
