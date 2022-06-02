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


#import "ZMTransportPushChannel.h"

@import WireSystem;
#import "ZMTransportRequestScheduler.h"
#import "ZMTransportSession+internal.h"
#import "ZMPushChannelConnection.h"
#import "ZMTLogging.h"
#import <WireTransport/WireTransport-Swift.h>

#include <stdatomic.h>

static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_PUSHCHANNEL;

@interface ZMTransportPushChannel ()

@property (nonatomic) ZMTransportRequestScheduler *scheduler;
@property (nonatomic) Class pushChannelClass;
@property (nonatomic) id <BackendEnvironmentProvider> environment;
@property (nonatomic) NSString *userAgentString;
@property (nonatomic, weak) id<ZMPushChannelConsumer> consumer;
@property (nonatomic, weak) id<ZMSGroupQueue> consumerQueue;
@property (nonatomic) ZMPushChannelConnection *pushChannel;
@property (nonatomic, readonly) BOOL shouldBeOpen;

@end



@interface ZMTransportPushChannel (Consumer) <ZMPushChannelConnectionConsumer>
@end



@implementation ZMTransportPushChannel

@synthesize clientID = _clientID;
@synthesize keepOpen = _keepOpen;
@synthesize accessToken = _accessToken;

- (void)setClientID:(NSString *)clientID
{
    [self.scheduler performGroupedBlock:^{
        self->_clientID = [clientID copy];
        
        [self.pushChannel close];
        [self scheduleOpen];
    }];
}

- (void)setAccessToken:(ZMAccessToken *)accessToken
{
    [self.scheduler performGroupedBlock:^{
        self->_accessToken = accessToken;
        
        [self.pushChannel close];
        [self scheduleOpen];
    }];
}

- (void)setKeepOpen:(BOOL)keepOpen
{
    [self.scheduler performGroupedBlock:^{
        self->_keepOpen = keepOpen;
        
        [self closeIfNotAllowedToBeOpen];
        [self scheduleOpen];
    }];
}


ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithScheduler:(ZMTransportRequestScheduler *)scheduler userAgentString:(NSString *)userAgentString environment:(id <BackendEnvironmentProvider>)environment
                            queue:(NSOperationQueue * _Nonnull)queue;
{
    return [self initWithScheduler:scheduler userAgentString:userAgentString environment:environment pushChannelClass:nil];
}

- (instancetype)initWithScheduler:(ZMTransportRequestScheduler *)scheduler userAgentString:(NSString *)userAgentString environment:(id <BackendEnvironmentProvider>)environment pushChannelClass:(Class)pushChannelClass;
{
    self = [super init];
    if (self) {
        self.scheduler = scheduler;
        self.environment = environment;
        self.userAgentString = userAgentString;
        self.pushChannelClass = pushChannelClass ?: ZMPushChannelConnection.class;
    }
    return self;
}

- (void)dealloc {
    [self.scheduler tearDown];
}

- (void)setPushChannelConsumer:(id<ZMPushChannelConsumer>)consumer queue:(id<ZMSGroupQueue>)groupQueue;
{
    ZMLogInfo(@"Setting push channel consumer");
    
    if (consumer != nil) {
        Require(groupQueue != nil);
        [self.scheduler performGroupedBlock:^{
            self.consumerQueue = groupQueue;
            self.consumer = consumer;
            [self scheduleOpen];
        }];
    } else {
        [self close];
    }
}

- (void)close
{
    ZMLogInfo(@"Remove push channel consumer");
    
    [self.scheduler performGroupedBlock:^{
        self.consumer = nil;
        self.consumerQueue = nil;
        [self.pushChannel close];
    }];
}

- (void)scheduleOpen
{
    ZMLogInfo(@"Attempt to open push channel");
    
    if (self.shouldBeOpen) {
        ZMOpenPushChannelRequest *openPushChannelItem = [[ZMOpenPushChannelRequest alloc] init];
        [self.scheduler addItem:openPushChannelItem];
    }
}

- (void)closeIfNotAllowedToBeOpen
{
    if (self.pushChannel.isOpen && !self.shouldBeOpen) {
        [self.pushChannel close];
    }
}

- (BOOL)shouldBeOpen
{
    return self.clientID != nil && self.accessToken != nil && self.consumer != nil && self.keepOpen;
}

- (void)open
{
    if (!self.pushChannel.isOpen && self.shouldBeOpen) {
        ZMLogInfo(@"Opening push channel");
        self.pushChannel = [[self.pushChannelClass alloc] initWithEnvironment:self.environment consumer:self queue:self.scheduler accessToken:self.accessToken clientID:self.clientID userAgentString:self.userAgentString];
    }
}

- (void)reachabilityDidChange:(ZMReachability *)reachability;
{
    BOOL didEnterWifi = !reachability.isMobileConnection && reachability.oldIsMobileConnection;
    BOOL didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable;
    
    if (didEnterWifi) {
        [self.pushChannel close];
    } else if (self.pushChannel.isOpen) {
        if (didGoOnline && !self.pushChannel.didCompleteHandshake) {
            // If we regain internet access after the handshake frame has been sent, but before the channel is closed, we have an improperly working channel
            // We need to close this one and open a new one (when `pushChannelDidClose:withResponse:` is called)
            [self.pushChannel close];
        } else {
            [self.pushChannel checkConnection];
        }
    }
}

@end



@implementation ZMTransportPushChannel (Consumer)

- (void)pushChannel:(ZMPushChannelConnection *)connection didReceiveTransportData:(id<ZMTransportData>)data
{
    ZMLogInfo(@"Received payload on push channel.");

    [self.networkStateDelegate didReceiveData];
    
    [self.consumerQueue performGroupedBlock:^{
        [self.consumer pushChannelDidReceiveTransportData:data];
    }];
    
}

- (void)pushChannel:(ZMPushChannelConnection *)connection didCloseWithResponse:(NSHTTPURLResponse *)response error:(NSError *)error
{
    ZMLogInfo(@"Push channel did close.");
    
    // Immediately try to re-open the push channel
    [self scheduleOpen];
    
    [self.consumerQueue performGroupedBlock:^{
        [self.consumer pushChannelDidClose];
    }];
    
    if (response != nil) {
        [self.scheduler processCompletedURLResponse:response URLError:nil];
    } else if (error != nil) {
        [self.scheduler processWebSocketError:error];
    }

    if (connection == self.pushChannel) {
        self.pushChannel = nil;
    }
}

- (void)pushChannel:(ZMPushChannelConnection *)connection didOpenWithResponse:(NSHTTPURLResponse *)response
{
    ZMLogInfo(@"Push channel did open.");

    [self.consumerQueue performGroupedBlock:^{
        [self.consumer pushChannelDidOpen];
    }];
    
    if (response != nil) {
        [self.scheduler processCompletedURLResponse:response URLError:nil];
    }
}

@end
