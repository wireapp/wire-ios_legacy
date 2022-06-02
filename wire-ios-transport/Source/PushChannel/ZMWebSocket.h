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

@protocol ZMWebSocketConsumer;
@protocol ZMSGroupQueue;
@protocol BackendTrustProvider;
@class NetworkSocket;

extern NSString * const ZMWebSocketErrorDomain;
typedef NS_ENUM(NSInteger, ZMWebSocketErrorCode) {
    ZMWebSocketErrorCodeInvalid = 0,
    ZMWebSocketErrorCodeLostConnection
};


@interface ZMWebSocket : NSObject

- (instancetype)initWithConsumer:(id<ZMWebSocketConsumer>)consumer
                           queue:(dispatch_queue_t)queue
                           group:(ZMSDispatchGroup *)group
                             url:(NSURL *)url
                   trustProvider:(id<BackendTrustProvider>)trustProvider
          additionalHeaderFields:(NSDictionary *)additionalHeaderFields;

- (instancetype)initWithConsumer:(id<ZMWebSocketConsumer>)consumer
                           queue:(dispatch_queue_t)queue
                           group:(ZMSDispatchGroup *)group
                   networkSocket:(NetworkSocket *)networkSocket
              networkSocketQueue:(dispatch_queue_t)queue
                             url:(NSURL *)url
                   trustProvider:(id<BackendTrustProvider>)trustProvider
          additionalHeaderFields:(NSDictionary *)additionalHeaderFields NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, weak) id<ZMWebSocketConsumer> consumer;

- (void)close;
- (void)sendTextFrameWithString:(NSString *)string;
- (void)sendBinaryFrameWithData:(NSData *)data;
- (void)sendPingFrame;


/**
 When this object is created, hand shake is initialized as not complete.
 After didParseHandshakeInBuffer is called and handshaked sucessfully this method will return true.

 @return return ture if handshake is completed
 */
- (BOOL)handshakeCompleted;

@end

@protocol ZMWebSocketConsumer <NSObject>

- (void)webSocketDidCompleteHandshake:(ZMWebSocket *)websocket HTTPResponse:(NSHTTPURLResponse *)response;
- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithData:(NSData *)data;
- (void)webSocket:(ZMWebSocket *)webSocket didReceiveFrameWithText:(NSString *)text;
- (void)webSocketDidClose:(ZMWebSocket *)webSocket HTTPResponse:(NSHTTPURLResponse *)response error:(NSError *)error;

@end
