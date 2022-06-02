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


#import <Foundation/Foundation.h>
#import <WireTransport/ZMTransportData.h>


NS_ASSUME_NONNULL_BEGIN

@protocol ZMPushChannelConsumer;
@protocol ZMSGroupQueue;
@protocol BackendEnvironmentProvider;
@class ZMWebSocket;
@class ZMAccessToken;
@class ZMPushChannelConnection;

@protocol ZMPushChannelConnectionConsumer <NSObject>

- (void)pushChannel:(ZMPushChannelConnection *)connection didReceiveTransportData:(id<ZMTransportData>)data;
- (void)pushChannel:(ZMPushChannelConnection *)connection didCloseWithResponse:(nullable NSHTTPURLResponse *)response error:(nullable NSError *)error;
- (void)pushChannel:(ZMPushChannelConnection *)connection didOpenWithResponse:(nullable NSHTTPURLResponse *)response;

@end


/// This is a one-shot connection to the backend's /await endpoint. Once closed,
/// a new instance needs to be created.
@interface ZMPushChannelConnection : NSObject

- (instancetype)initWithEnvironment:(id <BackendEnvironmentProvider>)environment
                           consumer:(id<ZMPushChannelConnectionConsumer>)consumer
                              queue:(id<ZMSGroupQueue>)queue
                        accessToken:(ZMAccessToken *)accessToken
                           clientID:(NSString *)clientID
                    userAgentString:(NSString *)userAgentString;

- (instancetype)initWithEnvironment:(id <BackendEnvironmentProvider>)environment
                           consumer:(id<ZMPushChannelConnectionConsumer>)consumer
                              queue:(id<ZMSGroupQueue>)queue
                          webSocket:(nullable ZMWebSocket *)webSocket
                        accessToken:(ZMAccessToken *)accessToken
                           clientID:(nullable NSString *)clientID
                    userAgentString:(NSString *)userAgentString NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, weak) id<ZMPushChannelConnectionConsumer> consumer;
@property (nonatomic, readonly) BOOL isOpen;
@property (nonatomic, readonly) BOOL didCompleteHandshake;

- (void)checkConnection;

- (void)close;

@end


@interface ZMPushChannelConnection (Testing)

@property (nonatomic) NSTimeInterval pingInterval;

@end

NS_ASSUME_NONNULL_END
