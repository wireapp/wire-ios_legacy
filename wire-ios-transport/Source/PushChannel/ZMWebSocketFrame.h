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


@import Foundation;
@import WireSystem;

@class DataBuffer;


typedef NS_ENUM(uint8_t, ZMWebSocketFrameType) {
    ZMWebSocketFrameTypeInvalid = 0,
    ZMWebSocketFrameTypeText,
    ZMWebSocketFrameTypeBinary,
    ZMWebSocketFrameTypePing,
    ZMWebSocketFrameTypePong,
    ZMWebSocketFrameTypeClose,
};

extern NSString * const ZMWebSocketFrameErrorDomain;
typedef NS_ENUM(NSInteger, ZMWebSocketFrameErrorCode) {
    ZMWebSocketFrameErrorCodeInvalid = 0,
    ZMWebSocketFrameErrorCodeDataTooShort,
    ZMWebSocketFrameErrorCodeParseError,
};





/// Web Socket Frame according to RFC 6455
/// http://tools.ietf.org/html/rfc6455
@interface ZMWebSocketFrame : NSObject

/// The passed in error will be set to @c ZMWebSocketFrameErrorDomain and one of
/// @c ZMWebSocketFrameErrorCodeDataTooShort or @c ZMWebSocketFrameErrorCodeParseError
- (instancetype)initWithDataBuffer:(DataBuffer *)dataBuffer error:(NSError **)error NS_DESIGNATED_INITIALIZER ZM_NON_NULL(1, 2);

/// Creates a binary frame with the given payload.
- (instancetype)initWithBinaryFrameWithPayload:(NSData *)payload NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTextFrameWithPayload:(NSString *)payload NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPongFrame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPingFrame NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) ZMWebSocketFrameType frameType;
@property (nonatomic, readonly, copy) NSData *payload;

@property (nonatomic, readonly) dispatch_data_t frameData;

@end
