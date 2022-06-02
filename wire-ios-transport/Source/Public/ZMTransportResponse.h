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

typedef NS_ENUM(uint8_t, ZMTransportResponseContentType) {
    ZMTransportResponseContentTypeInvalid,
    ZMTransportResponseContentTypeEmpty,
    ZMTransportResponseContentTypeImage,
    ZMTransportResponseContentTypeJSON,
};


typedef NS_ENUM(uint8_t, ZMTransportResponseStatus) {
    ZMTransportResponseStatusSuccess,
    ZMTransportResponseStatusTemporaryError,
    ZMTransportResponseStatusPermanentError,
    ZMTransportResponseStatusExpired,
    ZMTransportResponseStatusTryAgainLater,
};




@interface ZMTransportResponse : NSObject

- (instancetype)initWithHTTPURLResponse:(NSHTTPURLResponse *)HTTPResponse data:(nullable NSData *)data error:(nullable NSError *)error apiVersion:(int)apiVersion;

- (instancetype)initWithImageData:(NSData *)imageData HTTPStatus:(NSInteger)status transportSessionError:(nullable NSError *)error headers:(nullable NSDictionary *)headers apiVersion:(int)apiVersion;

- (instancetype)initWithPayload:(nullable id<ZMTransportData>)payload HTTPStatus:(NSInteger)status transportSessionError:(nullable NSError *)error headers:(nullable NSDictionary *)headers apiVersion:(int)apiVersion;
+ (instancetype)responseWithPayload:(nullable id<ZMTransportData>)payload HTTPStatus:(NSInteger)status transportSessionError:(nullable NSError *)error headers:(nullable NSDictionary *)headers apiVersion:(int)apiVersion;
+ (instancetype)responseWithPayload:(nullable id<ZMTransportData>)payload HTTPStatus:(NSInteger)status transportSessionError:(nullable NSError *)error apiVersion:(int)apiVersion;
+ (instancetype)responseWithTransportSessionError:(NSError *)error apiVersion:(int)apiVersion;

@property (nonatomic, readonly, nullable) id<ZMTransportData> payload;
@property (nonatomic, readonly, nullable) NSData * imageData;
@property (nonatomic, readonly, copy, nullable) NSDictionary * headers;

@property (nonatomic, readonly) NSInteger HTTPStatus;
@property (nonatomic, readonly, nullable) NSError * transportSessionError;
@property (nonatomic) ZMSDispatchGroup *dispatchGroup;

@property (nonatomic, readonly, nullable) NSHTTPURLResponse * rawResponse;
@property (nonatomic, readonly, nullable) NSData * rawData;

@property (nonatomic, readonly) ZMTransportResponseStatus result;

- (nullable NSString *)payloadLabel;

@property (nonatomic, nullable) NSDate *startOfUploadTimestamp;

/// The api version associated with the response.
///
/// In order to correctly handle the response, the api version must
/// be taken into account, since the response may change over different
/// versions of the same endpoint.
@property (nonatomic, readonly) int apiVersion;
@end


@interface ZMTransportResponse (PermanentlyUnavailable)
- (BOOL)isPermanentylUnavailableError;
@end


@interface NSHTTPURLResponse (ZMTransportResponse)

- (ZMTransportResponseContentType)zmContentTypeForBodyData:(NSData *)bodyData;

@end

NS_ASSUME_NONNULL_END

