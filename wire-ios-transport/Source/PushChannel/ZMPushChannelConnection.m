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
@import WireUtilities;

#import "ZMPushChannelConnection.h"
#import "ZMPushChannelConnection+WebSocket.h"
#import "ZMWebSocket.h"
#import <libkern/OSAtomic.h>
#import "ZMTLogging.h"
#import <WireTransport/WireTransport-Swift.h>

static NSString* ZMLogTag = ZMT_LOG_TAG_PUSHCHANNEL;


@interface ZMPushChannelConnection ()

@property (nonatomic, weak) id<ZMPushChannelConnectionConsumer> consumer;
@property (nonatomic, weak) id<ZMSGroupQueue> consumerQueue;
@property (nonatomic) ZMWebSocket *webSocket;
@property (nonatomic) dispatch_queue_t webSocketQueue;
@property (nonatomic) ZMSDispatchGroup *webSocketGroup;
@property (nonatomic) NSTimeInterval pingInterval;
@property (nonatomic) NSTimer *pingTimer;
@property (nonatomic) NSHTTPURLResponse *closeResponse;
@property (nonatomic) ZMAtomicInteger *closedFlag;

@end

@implementation ZMPushChannelConnection

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should not use -init" userInfo:nil];
    return [self initWithEnvironment:nil consumer:nil queue:nil accessToken:nil clientID:nil userAgentString:nil];
}

- (instancetype)initWithEnvironment:(id <BackendEnvironmentProvider>)environment consumer:(id<ZMPushChannelConnectionConsumer>)consumer queue:(id<ZMSGroupQueue>)queue accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;
{
    return [self initWithEnvironment:environment consumer:consumer queue:queue webSocket:nil accessToken:accessToken clientID:clientID userAgentString:userAgentString];
}

- (instancetype)initWithEnvironment:(id <BackendEnvironmentProvider>)environment consumer:(id<ZMPushChannelConnectionConsumer>)consumer queue:(id<ZMSGroupQueue>)queue webSocket:(ZMWebSocket *)webSocket accessToken:(ZMAccessToken *)accessToken clientID:(NSString *)clientID userAgentString:(NSString *)userAgentString;
{
    VerifyReturnNil(consumer != nil);
    VerifyReturnNil(queue != nil);
    self = [super init];
    if (self != nil) {
        self.consumer = consumer;
        self.consumerQueue = queue;
        self.webSocketQueue = dispatch_queue_create("ZMPushChannel.websocket", 0);
        self.webSocketGroup = queue.dispatchGroup;

        NSURL *URL = [environment.backendWSURL URLByAppendingPathComponent:@"/await"];
        if (URL != nil && clientID != nil) {
            NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"client" value:clientID]];
            URL = components.URL;
        }
        
        if (webSocket == nil) {
            NSMutableDictionary *headers = [[accessToken httpHeaders] mutableCopy];
            if (0 < userAgentString.length) {
                headers[@"User-Agent"] = [userAgentString copy];
            }
            webSocket = [[ZMWebSocket alloc] initWithConsumer:self queue:self.webSocketQueue group:self.webSocketGroup url:URL trustProvider:environment additionalHeaderFields:headers];
        }
        self.webSocket = webSocket;
        self.pingInterval = 40;
        self.closedFlag = [[ZMAtomicInteger alloc] initWithInteger:0];
    }
    return self;
}

- (BOOL)isOpen;
{
    return self.closedFlag.rawValue == NO;
}

- (BOOL)didCompleteHandshake
{
    return self.webSocket.handshakeCompleted;
}

- (void)checkConnection;
{
    ZM_WEAK(self);
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        ZM_STRONG(self);
        [self.webSocket sendPingFrame];
    }];
}

- (void)close
{
    [self closeWithHTTPResponse:nil error:nil];
}

- (void)closeWithHTTPResponse:(NSHTTPURLResponse *)response error:(NSError *)error
{
    // The compare & swap ensure that the code only runs if the values of isClosed was 0 and sets it to 1.
    // The check for 0 and setting it to 1 happen as a single atomic operation.
    if ([self.closedFlag setValueWithEqualityCondition:NO newValue:YES]) {
        ZMLogDebug(@"-[%@ %@]", self.class, NSStringFromSelector(_cmd));
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        id<ZMSGroupQueue> queue = self.consumerQueue;
        self.consumerQueue = nil;
        
        [self.webSocket close];
        
        id<ZMPushChannelConnectionConsumer> consumer = self.consumer;
        self.consumer = nil;
        
        ZMPushChannelConnection *channel = self;

        [self stopPingTimer];
        [queue performGroupedBlock:^{
            [consumer pushChannel:channel didCloseWithResponse:response error:error];
        }];
    }
}

- (void)dealloc;
{
    Require(self.closedFlag.rawValue == YES);
}


- (void)setPingInterval:(NSTimeInterval)pingInterval
{
    ZM_WEAK(self);
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        ZM_STRONG(self);
        if (nil == self) {
            return;
        }
        self->_pingInterval = pingInterval;
        [self startPingTimer];
    }];
}

- (NSTimeInterval)shiftedPingInterval;
{
    double const shiftAmount = 0.1; // 10% shift
    double const shift = (2. * (arc4random() / (double) UINT32_MAX) - 1.) * shiftAmount;
    return self.pingInterval * (1. + shift);
}

- (void)startPingTimer;
{
    [self.pingTimer invalidate];
    NSTimeInterval const interval = self.shiftedPingInterval;
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(sendPing:) userInfo:nil repeats:YES];
    timer.tolerance = interval * 0.1;
    self.pingTimer = timer;
    [self.webSocketGroup asyncOnQueue:dispatch_get_main_queue() block:^{
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        // Fire immediately to check if the socket is still alive after application resume
        [timer fire];
    }];
}

- (void)sendPing:(NSTimer *)timer
{
    ZM_WEAK(self);
    [self.webSocketGroup asyncOnQueue:self.webSocketQueue block:^{
        ZM_STRONG(self);
        if (timer == self.pingTimer) {
            [self.webSocket sendPingFrame];
        }
    }];
}

- (void)stopPingTimer;
{
    NSTimer *timer = self.pingTimer;
    self.pingTimer = nil;
    [self.webSocketGroup asyncOnQueue:dispatch_get_main_queue() block:^{
        [timer invalidate];
    }];
}

@end



@implementation ZMPushChannelConnection (ZMWebSocketConsumer)

-(void)webSocketDidCompleteHandshake:(ZMWebSocket * __unused)websocket HTTPResponse:(NSHTTPURLResponse *)response
{
    ZMLogDebug(@"-[%@ %@]", self.class, NSStringFromSelector(_cmd));
    ZM_WEAK(self);
    [self.consumerQueue performGroupedBlock:^{
        ZM_STRONG(self);
        [self.consumer pushChannel:self didOpenWithResponse:response];
    }];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithText:(NSString *)text;
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    [self webSocket:webSocket didReceiveFrameWithData:data];
}

- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithData:(NSData *)data;
{
    VerifyReturn(data != nil);
    NOT_USED(webSocket);
    NSError *error;
    id<ZMTransportData> transportData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (transportData == nil) {
        ZMLogError(@"Failed to parse data into JSON from push channel: %@", error);
    } else {
        ZM_WEAK(self);
        [self.consumerQueue performGroupedBlock:^{
            ZM_STRONG(self);
            [self.consumer pushChannel:self didReceiveTransportData:transportData];
        }];
    }
}

- (void)webSocketDidClose:(ZMWebSocket * __unused)webSocket HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *)error;
{
    [self closeWithHTTPResponse:response error:error];
}

@end
