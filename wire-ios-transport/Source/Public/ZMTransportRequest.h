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
#import <WireSystem/WireSystem.h>

NS_ASSUME_NONNULL_BEGIN

@class ZMTransportResponse;
@protocol ZMTransportData;
@protocol ZMSGroupQueue;
@class ZMTaskIdentifier;
@class ZMURLSession;

typedef void(^ZMTaskCreatedBlock)(ZMTaskIdentifier *);
typedef void(^ZMCompletionHandlerBlock)(ZMTransportResponse *);
typedef void(^ZMAccessTokenHandlerBlock)(NSString *token, NSString *type);
typedef void(^ZMProgressHandlerBlock)(float);

extern const NSTimeInterval ZMTransportRequestDefaultExpirationInterval;


@interface ZMCompletionHandler : NSObject

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMCompletionHandlerBlock)block;
@property (nonatomic, readonly, weak) id<ZMSGroupQueue> groupQueue;

@end;


@interface ZMTaskCreatedHandler : NSObject

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMTaskCreatedBlock)block;
@property (nonatomic, readonly, weak) id<ZMSGroupQueue> groupQueue;

@end


@interface ZMTaskProgressHandler : NSObject

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMProgressHandlerBlock)block;
@property (nonatomic, readonly, weak) id<ZMSGroupQueue> groupQueue;

@end


typedef NS_ENUM(uint8_t, ZMTransportRequestMethod) {
    ZMMethodGET,
    ZMMethodDELETE,
    ZMMethodPUT,
    ZMMethodPOST,
    ZMMethodHEAD
};

typedef NS_ENUM(uint8_t, ZMTransportRequestAuth) {
    ZMTransportRequestAuthNone, ///< Does not needs an access token and does not generate one
    ZMTransportRequestAuthNeedsAccess, ///< Needs an access token
    ZMTransportRequestAuthCreatesCookieAndAccessToken, ///< Does not need an access token, but the response will contain one
    ZMTransportRequestAuthNeedsCookieAndAccessToken, /// < Needs both the cookie and access token
};

typedef NS_ENUM(int8_t, ZMTransportAccept) {
    ZMTransportAcceptAnything, ///< Maps to "Accept: */*" HTTP header
    ZMTransportAcceptTransportData, ///< Maps to "Accept: application/json" HTTP header
    ZMTransportAcceptImage, ///< Maps to "Accept: image/*" HTTP header
};


@interface ZMTransportRequest : NSObject

+ (NSString *)stringForMethod:(ZMTransportRequestMethod)method;
+ (ZMTransportRequestMethod)methodFromString:(NSString *)string;

/// Returns a request that needs authentication, ie. @c ZMTransportRequestAuthNeedsAccess
- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(nullable id <ZMTransportData>)payload apiVersion:(int)apiVersion;
- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(nullable id <ZMTransportData>)payload authentication:(ZMTransportRequestAuth)authentication apiVersion:(int)apiVersion;

+ (instancetype)requestWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(nullable id <ZMTransportData>)payload apiVersion:(int)apiVersion;
+ (instancetype)requestWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(nullable id <ZMTransportData>)payload shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion;

+ (instancetype)requestGetFromPath:(NSString *)path apiVersion:(int)apiVersion;
+ (instancetype)compressedGetFromPath:(NSString *)path apiVersion:(int)apiVersion;
+ (instancetype)uploadRequestWithFileURL:(NSURL *)url path:(NSString *)path contentType:(NSString *)contentType apiVersion:(int)apiVersion;

+ (instancetype)emptyPutRequestWithPath:(NSString *)path apiVersion:(int)apiVersion;
+ (instancetype)imageGetRequestFromPath:(NSString *)path apiVersion:(int)apiVersion;

/// Creates a request with the given @c binary data for the body and the given @c type to be used as the content type.
/// @c type is a (Uniform Type Identifier) UTI.
/// @link https://en.wikipedia.org/wiki/Uniform_Type_Identifier @/link
/// @link https://developer.apple.com/library/ios/documentation/General/Conceptual/DevPedia-CocoaCore/UniformTypeIdentifier.html @/link
- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method binaryData:(nullable NSData *)data type:(nullable NSString *)type contentDisposition:(nullable NSDictionary *)contentDisposition apiVersion:(int)apiVersion;
- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method binaryData:(nullable NSData *)data type:(nullable NSString *)type contentDisposition:(nullable NSDictionary *)contentDisposition shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion;


@property (nonatomic, readonly) NSString *methodAsString;
@property (nonatomic, readonly, copy, nullable) id<ZMTransportData> payload;
@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly) ZMTransportRequestMethod method;
@property (nonatomic, readonly, copy, nullable) NSData *binaryData;
@property (nonatomic, readonly, nullable) NSURL *fileUploadURL;
@property (nonatomic, readonly, copy, nullable) NSString *binaryDataType; ///< Uniform type identifier (UTI) of the binary data
@property (nonatomic, readonly) BOOL needsAuthentication;
@property (nonatomic, readonly) BOOL needsCookie;
@property (nonatomic, readonly) BOOL responseWillContainAccessToken;
@property (nonatomic, readonly) BOOL responseWillContainCookie;
@property (nonatomic, readonly, nullable) NSDate *expirationDate;
@property (nonatomic, readonly) BOOL shouldCompress;
@property (nonatomic) BOOL shouldFailInsteadOfRetry;
@property (nonatomic) BOOL doesNotFollowRedirects;

/// The api version for which this request was made against.
///
/// In order to correctly handle the response to this request, the api version must
/// be taken into account. Each request is paired with a response, so the api version
/// of the response can be derived from this value.
@property (nonatomic, readonly) int apiVersion;

/// If true, the request should only be sent through background session
@property (nonatomic, readonly) BOOL shouldUseOnlyBackgroundSession;
@property (nonatomic, readonly) BOOL shouldUseVoipSession;

@property (nonatomic, readonly, copy, nullable) NSDictionary *contentDisposition; ///< C.f. <https://tools.ietf.org/html/rfc2183>

- (void)addTaskCreatedHandler:(ZMTaskCreatedHandler *)taskCreatedHandler NS_SWIFT_NAME(add(_:));
- (void)addCompletionHandler:(ZMCompletionHandler *)completionHandler NS_SWIFT_NAME(add(_:));
- (void)addProgressHandler:(ZMTaskProgressHandler *)progressHandler NS_SWIFT_NAME(add(_:));
- (void)callTaskCreationHandlersWithIdentifier:(NSUInteger)identifier sessionIdentifier:(NSString *)sessionIdentifier;
- (void)completeWithResponse:(ZMTransportResponse *)response;
- (void)updateProgress:(float)progress;
- (BOOL)isEqualToRequest:(ZMTransportRequest *)request;
- (void)addValue:(NSString *)value forAdditionalHeaderField:(NSString *)headerField;
- (void)expireAfterInterval:(NSTimeInterval)interval;
- (void)expireAtDate:(NSDate *)date;

- (BOOL)hasRequiredPayload;

/// If this is called, the request is going to be executed only on a background session
- (void)forceToBackgroundSession;

/// If this is called, the request is going to be executed on the voip session only
- (void)forceToVoipSession;

@property (nonatomic, readonly) ZMTransportAccept acceptedResponseMediaTypes; ///< C.f. RFC 7231 section 5.3.2 <http://tools.ietf.org/html/rfc7231#section-5.3.2>

@end


@interface ZMTransportRequest (ImageUpload)

+ (_Null_unspecified instancetype)postRequestWithPath:(NSString *)path imageData:(NSData *)data contentDisposition:(NSDictionary *)contentDisposition apiVersion:(int)apiVersion;
+ (_Null_unspecified instancetype)multipartRequestWithPath:(NSString *)path imageData:(NSData *)data metaData:(NSDictionary *)metaData apiVersion:(int)apiVersion;
+ (_Null_unspecified instancetype)multipartRequestWithPath:(NSString *)path imageData:(NSData *)data metaData:(NSDictionary *)metaData mediaContentType:(NSString *)mediaContentType apiVersion:(int)apiVersion;

+ (instancetype)multipartRequestWithPath:(NSString *)path
                               imageData:(NSData *)data
                                metaData:(NSData *)metaData
                     metaDataContentType:(NSString *)metaDataContentType
                        mediaContentType:(NSString *)mediaContentType
                              apiVersion:(int)apiVersion;

- (nullable NSArray *)multipartBodyItems;

@end


@class ZMObjectStrategy;
@protocol ZMObjectStrategy;
@class ZMSyncState;
@interface ZMTransportRequest (Debugging)

@property (nonatomic, readonly, nullable) NSDate *startOfUploadTimestamp;
@property (nonatomic, readonly) NSUInteger contentDebugInformationHash;

- (void)setDebugInformationTranscoder:(NSObject *)transcoder;
- (void)setDebugInformationState:(ZMSyncState *)state;
- (void)addContentDebugInformation:(NSString *)debugInformation;

/// Marks the start of the upload time point
- (void)markStartOfUploadTimestamp;

@end


NS_ASSUME_NONNULL_END
