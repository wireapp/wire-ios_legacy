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


@import WireUtilities;
@import WireSystem;
@import ImageIO;
@import MobileCoreServices;

#import <WireTransport/WireTransport-Swift.h>

#import "ZMTransportRequest+Internal.h"
#import "ZMTransportData.h"
#import "ZMTransportResponse.h"
#import "ZMTransportCodec.h"
#import "NSData+Multipart.h"
#import "ZMURLSession.h"
#import "ZMTaskIdentifier.h"
#import "ZMTransportRequest+AssetGet.h"

const NSTimeInterval ZMTransportRequestDefaultExpirationInterval = 60;
const NSTimeInterval ZMTransportRequestReducedExpirationInterval = 25;

typedef NS_ENUM(NSUInteger, ZMTransportRequestSessionType) {
    ZMTransportRequestSessionTypeUseDefaultSession,
    ZMTransportRequestSessionTypeUseBackgroundSessionOnly,
    ZMTransportRequestSessionTypeUseVoipSessionOnly,
};

@interface ZMCompletionHandler ()


@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;
@property (nonatomic, copy) ZMCompletionHandlerBlock block;

@end

@implementation ZMCompletionHandler

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMCompletionHandlerBlock)block;
{
    RequireString(block != nil, "Invalid completion handler");
    RequireString(groupQueue != nil, "Invalid group queue");
    ZMCompletionHandler *handler = [[self alloc] init];
    if (handler != nil) {
        handler.groupQueue = groupQueue;
        handler.block = block;
    }
    return (ZMCompletionHandler * _Nonnull)handler;
}

@end;


@interface ZMTaskCreatedHandler ()

@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;
@property (nonatomic, copy) ZMTaskCreatedBlock block;

@end

@implementation ZMTaskCreatedHandler

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMTaskCreatedBlock)block;
{
    RequireString(block != nil, "Invalid completion handler");
    RequireString(groupQueue != nil, "Invalid group queue");
    ZMTaskCreatedHandler *handler = [[self alloc] init];
    if (handler != nil) {
        handler.groupQueue = groupQueue;
        handler.block = block;
    }
    return (ZMTaskCreatedHandler * _Nonnull)handler;
}

@end;




@interface ZMTaskProgressHandler ()

@property (nonatomic, weak) id<ZMSGroupQueue> groupQueue;
@property (nonatomic, copy) ZMProgressHandlerBlock block;

@end

@implementation ZMTaskProgressHandler

+ (instancetype)handlerOnGroupQueue:(id<ZMSGroupQueue>)groupQueue block:(ZMProgressHandlerBlock)block;
{
    RequireString(block != nil, "Invalid completion handler");
    RequireString(groupQueue != nil, "Invalid group queue");
    ZMTaskProgressHandler *handler = [[self alloc] init];
    if (handler != nil) {
        handler.groupQueue = groupQueue;
        handler.block = block;
    }
    return (ZMTaskProgressHandler * _Nonnull)handler;
}

@end;





@interface ZMTransportRequest ()

@property (nonatomic, copy) id<ZMTransportData> payload;
@property (nonatomic, copy) NSString *path;
@property (nonatomic) ZMTransportRequestMethod method;
@property (nonatomic, copy) NSData *binaryData;
@property (nonatomic, copy) NSString *binaryDataType;
@property (nonatomic, copy) NSDictionary *contentDisposition;
@property (nonatomic) NSMutableArray <ZMTaskCreatedHandler*> *taskCreatedHandlers;
@property (nonatomic) NSMutableArray <ZMCompletionHandler *> *completionHandlers;
@property (nonatomic) NSMutableArray <ZMTaskProgressHandler *> *progressHandlers;
@property (nonatomic) BOOL needsAuthentication;
@property (nonatomic) BOOL needsCookie;
@property (nonatomic) BOOL responseWillContainAccessToken;
@property (nonatomic) BOOL responseWillContainCookie;
@property (nonatomic) ZMTransportAccept acceptedResponseMediaTypes; ///< C.f. RFC 7231 section 5.3.2 <http://tools.ietf.org/html/rfc7231#section-5.3.2>
@property (nonatomic) NSDate *timeoutDate;
@property (nonatomic) NSMutableArray<NSString *>* debugInformation;
/// Hash of the content debug information. This is used to identify the content of the request (e.g. detect repeated requests with the same content)
@property (nonatomic) NSUInteger contentDebugInformationHash;
@property (nonatomic) BOOL shouldCompress;
@property (nonatomic) NSURL *fileUploadURL;
@property (nonatomic) NSDate *startOfUploadTimestamp;
@property (nonatomic) ZMTransportRequestSessionType transportSessionType;
@property (nonatomic) float progress;
@property (nonatomic) NSMutableDictionary <NSString *, NSString *> *additionalHeaderFields;
@property (nonatomic) BackgroundActivity *activity;
@property (nonatomic) int apiVersion;

@end



@implementation ZMTransportRequest

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload apiVersion:(int)apiVersion
{
    return [self initWithPath:path method:method payload:payload authentication:ZMTransportRequestAuthNeedsAccess shouldCompress:NO apiVersion: apiVersion];
}

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion
{
    return [self initWithPath:path method:method payload:payload authentication:ZMTransportRequestAuthNeedsAccess shouldCompress:shouldCompress apiVersion: apiVersion];
}

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload authentication:(ZMTransportRequestAuth)authentication shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion;
{
    self = [super init];
    if (self) {
        self.payload = payload;
        self.path = apiVersion == 0 ? path : [NSString stringWithFormat:@"/v%d%@", apiVersion, path];
        self.method = method;
        self.needsAuthentication = (authentication == ZMTransportRequestAuthNeedsAccess || authentication == ZMTransportRequestAuthNeedsCookieAndAccessToken);
        self.needsCookie = (authentication == ZMTransportRequestAuthNeedsCookieAndAccessToken);
        self.responseWillContainAccessToken = (authentication == ZMTransportRequestAuthCreatesCookieAndAccessToken);
        self.responseWillContainCookie = (authentication == ZMTransportRequestAuthCreatesCookieAndAccessToken);
        self.acceptedResponseMediaTypes = ZMTransportAcceptTransportData;
        self.shouldCompress = shouldCompress;
        self.debugInformation = [NSMutableArray array];
        self.contentDebugInformationHash = payload.hash;
        self.apiVersion = apiVersion;
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload authentication:(ZMTransportRequestAuth)authentication apiVersion:(int)apiVersion;
{
    return [self initWithPath:path method:method payload:payload authentication:authentication shouldCompress:NO apiVersion:apiVersion];
}

+ (instancetype)requestWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload apiVersion:(int)apiVersion
{
    return [[self class] requestWithPath:path method:method payload:payload shouldCompress:NO apiVersion:apiVersion];
}


+ (instancetype)requestWithPath:(NSString *)path method:(ZMTransportRequestMethod)method payload:(id <ZMTransportData>)payload shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion
{
    ZMTransportRequest *result = [[self alloc] initWithPath:path method:method payload:payload shouldCompress:shouldCompress apiVersion:apiVersion];
    Require(result.hasRequiredPayload);
    return result;
}

+ (instancetype)requestGetFromPath:(NSString *)path apiVersion:(int)apiVersion
{
    return [self requestWithPath:path method:ZMMethodGET payload:nil apiVersion:apiVersion];
}

+ (instancetype)compressedGetFromPath:(NSString *)path apiVersion:(int)apiVersion
{
    return [self requestWithPath:path method:ZMMethodGET payload:nil shouldCompress:YES apiVersion:apiVersion];
}

+ (instancetype)uploadRequestWithFileURL:(NSURL *)url path:(NSString *)path contentType:(NSString *)contentType apiVersion:(int)apiVersion;
{
    ZMTransportRequest *request = [[self.class alloc] initWithPath:path
                                                            method:ZMMethodPOST
                                                        binaryData:nil
                                                              type:contentType
                                                contentDisposition:nil
                                                        apiVersion:apiVersion];
    request.fileUploadURL = url;
    request.shouldFailInsteadOfRetry = YES;
    [request forceToBackgroundSession];
    return request;
}

+ (instancetype)emptyPutRequestWithPath:(NSString *)path apiVersion:(int)apiVersion;
{
    NSString *type = (__bridge NSString *) kUTTypeJSON;
    return [[self alloc] initWithPath:path method:ZMMethodPUT binaryData:[NSData data] type:type contentDisposition:nil apiVersion:apiVersion];
}

+ (instancetype)imageGetRequestFromPath:(NSString *)path apiVersion:(int)apiVersion;
{
    ZMTransportRequest *r = [self requestGetFromPath:path apiVersion:apiVersion];
    r.acceptedResponseMediaTypes = ZMTransportAcceptImage;
    Require(r.hasRequiredPayload);
    return r;
}

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method binaryData:(NSData *)data type:(NSString *)type contentDisposition:(NSDictionary *)contentDisposition apiVersion:(int)apiVersion;
{
    return [self initWithPath:path method:method binaryData:data type:type contentDisposition:contentDisposition shouldCompress:NO apiVersion:apiVersion];
}

- (instancetype)initWithPath:(NSString *)path method:(ZMTransportRequestMethod)method binaryData:(NSData *)data type:(NSString *)type contentDisposition:(NSDictionary *)contentDisposition shouldCompress:(BOOL)shouldCompress apiVersion:(int)apiVersion;
{
    self = [super init];
    if (self != nil) {
        self.path = apiVersion == 0 ? path : [NSString stringWithFormat:@"/v%d%@", apiVersion, path];
        self.method = method;
        self.binaryData = data;
        self.binaryDataType = type;
        self.contentDisposition = contentDisposition;
        self.needsAuthentication = YES;
        self.responseWillContainAccessToken = NO;
        self.acceptedResponseMediaTypes = ZMTransportAcceptTransportData;
        self.shouldCompress = shouldCompress;
        self.debugInformation = [NSMutableArray array];
        self.contentDebugInformationHash = data.hash;
        self.apiVersion = apiVersion;
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToRequest:other];
}

- (NSString *)methodAsString {
    return [self.class stringForMethod:self.method];
}

- (void)expireAfterInterval:(NSTimeInterval)interval;
{
    [self expireAtDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
}

- (void)expireAtDate:(NSDate *)date;
{
    _expirationDate = date;
}


- (BOOL)hasRequiredPayload;
{
    switch (self.method) {
        case ZMMethodGET:
        case ZMMethodHEAD:
            return ((self.payload == nil) &&
                    (self.binaryData == nil));
        case ZMMethodPOST:
        case ZMMethodDELETE:
            // POST and DELETE payload is optional
            return YES;
        case ZMMethodPUT:
            return ((self.payload != nil) ||
                    (self.binaryData != nil));
    }
}

- (void)setAcceptedResponseMediaTypeOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
{
    NSString *accept;
    switch (self.acceptedResponseMediaTypes) {
        case ZMTransportAcceptAnything:
            accept = @"*/*";
            break;
        case ZMTransportAcceptTransportData:
            accept = [ZMTransportCodec encodedContentType];
            break;
        case ZMTransportAcceptImage:
            accept = [[self imageMediaTypes] componentsJoinedByString:@", "];
            break;
    }
    [URLRequest addValue:accept forHTTPHeaderField:@"Accept"];
}

- (void)setBodyDataAndMediaTypeOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
{
    static NSString * const ContentTypeHeader = @"Content-Type";
    
    BOOL isFileUploadWithContentType = (self.binaryDataType != nil) && (self.fileUploadURL != nil);
    BOOL hasBinaryData = (self.binaryDataType != nil) && (self.binaryData != nil);
    
    if (hasBinaryData || isFileUploadWithContentType) {
        NSString *mediaType;
        if (mediaType == nil) {
            mediaType = [UTIHelper convertToMimeWithUti:self.binaryDataType];
        }
        if (mediaType != nil) {
            [URLRequest addValue:mediaType forHTTPHeaderField:ContentTypeHeader];
        }
        else {
            [URLRequest addValue:self.binaryDataType forHTTPHeaderField:ContentTypeHeader];
        }
        if (hasBinaryData) {
            URLRequest.HTTPBody = self.binaryData;
        }
    } else if (self.payload != nil) {
        URLRequest.HTTPBody = [ZMTransportCodec encodedTransportData:self.payload];
        [URLRequest addValue:[ZMTransportCodec encodedContentType] forHTTPHeaderField:ContentTypeHeader];
    }
    
    // Check if we want to use HTTP compression:
    //
    if (self.shouldCompress) {
        static NSUInteger const MaxUncompressedBodyLength = 500;
        
        if ([[URLRequest valueForHTTPHeaderField:ContentTypeHeader] isEqualToString:[ZMTransportCodec encodedContentType]] &&
            (MaxUncompressedBodyLength < URLRequest.HTTPBody.length))
        {
            // https://en.wikipedia.org/wiki/HTTP_compression
            NSData *compressed = [URLRequest.HTTPBody zm_gzipCompressedHTTPBody];
            if (compressed.length < URLRequest.HTTPBody.length) {
                URLRequest.HTTPBody = compressed;
                [URLRequest addValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
            }
        }
    }
}

- (void)addValue:(NSString *)value forAdditionalHeaderField:(NSString *)headerField
{
    if (nil == self.additionalHeaderFields) {
        self.additionalHeaderFields = @{headerField: value}.mutableCopy;
    } else {
        self.additionalHeaderFields[headerField] = value;
    }
}

- (void)setAdditionalHeaderFieldsOnHTTPRequest:(NSMutableURLRequest *)URLRequest
{
    [self.additionalHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *headerField, NSString *value, __unused BOOL *stop) {
        [URLRequest setValue:value forHTTPHeaderField:headerField];
    }];
}

- (void)setTimeoutIntervalOnRequestIfNeeded:(NSMutableURLRequest *)request
                  applicationIsBackgrounded:(BOOL)inBackground
                     usingBackgroundSession:(BOOL)usingBackgroundSession
{
    // We only want to override the timeout for requests using
    // the foregroundsession while we are running in the background
    if (! inBackground || usingBackgroundSession) {
        return;
    }
    
    request.timeoutInterval = ZMTransportRequestReducedExpirationInterval;
}

- (void)setContentDispositionOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
{
    if (self.contentDisposition == nil) {
        return;
    }
    NSMutableArray *components = [NSMutableArray array];
    NSArray *keys;
    ZM_ALLOW_MISSING_SELECTOR(keys = [self.contentDisposition.allKeys sortedArrayUsingSelector:@selector(compare:)]);
    for (NSString *key in keys) {
        NSString *stringValue = nil;
        id value = self.contentDisposition[key];
        if (value == [NSNull null]) {
            // nothing;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            if (value == (__bridge id) kCFBooleanTrue) {
                stringValue = @"true";
            } else if (value == (__bridge id) kCFBooleanFalse) {
                stringValue = @"false";
            } else {
                stringValue = [value description];
            }
        } else if ([value isKindOfClass:[NSString class]]) {
            stringValue = value;
        }
        if ((stringValue != nil) && ([stringValue rangeOfString:@" "].location != NSNotFound)) {
            // Not super nice.
            stringValue = [NSString stringWithFormat:@"\"%@\"", stringValue];
        }
        if (stringValue != nil) {
            [components addObject:[NSString stringWithFormat:@"%@=%@", key, stringValue]];
        } else {
            [components insertObject:key atIndex:0];
        }
    }
    NSString *disposition = [components componentsJoinedByString:@";"];
    [URLRequest addValue:disposition forHTTPHeaderField:@"Content-Disposition"];
}

- (NSString *)descriptionWithMethodAndPath;
{
    NSString *path = self.path;
    if (68 < path.length) {
        path = [[path substringToIndex:66] stringByAppendingFormat:@"[…](%u)", (unsigned) path.length];
    }
    return [NSString stringWithFormat:@"<%@: %p> %@ %@",
            self.class, self, [ZMTransportRequest stringForMethod:self.method], path];
}

- (NSArray *)imageMediaTypes;
{
    NSMutableArray *types = [NSMutableArray array];

    // Due to some refactoring for federation, the backend now sets the returned
    // content type for asset endpoints to application/json. We need to include this
    // in the accepted content types otherwise we'll get a 406 response error.
    [types addObject:@"application/json"];

    {
        for (NSString *uti in CFBridgingRelease(CGImageSourceCopyTypeIdentifiers())) {
            NSString *mimeType = [UTIHelper convertToMimeWithUti:uti];

            if ((mimeType == nil) || [mimeType hasPrefix:@"image/x-"] ||
                [UTIHelper conformsToVectorTypeWithUti:uti] ||
                [mimeType hasPrefix:@"application/"]) {
                continue;
            }
            [types addObject:mimeType];
        }
    }
    return types;
}

- (void)addTaskCreatedHandler:(ZMTaskCreatedHandler *)taskCreatedHandler;
{
    VerifyReturn(taskCreatedHandler != nil);
    if (self.taskCreatedHandlers == nil) {
        self.taskCreatedHandlers = [NSMutableArray arrayWithObject:taskCreatedHandler];
    } else {
        [self.taskCreatedHandlers addObject:taskCreatedHandler];
    }
}

- (void)callTaskCreationHandlersWithIdentifier:(NSUInteger)identifier sessionIdentifier:(NSString *)sessionIdentifier;
{
    ZMTaskIdentifier *taskIdentifier = [ZMTaskIdentifier identifierWithIdentifier:identifier sessionIdentifier:sessionIdentifier];
    NSString *label = [NSString stringWithFormat:@"Task created handler of REQ %@ %@ -> %@ ", self.methodAsString, self.path, taskIdentifier];
    ZMSDispatchGroup *handlerGroup = [ZMSDispatchGroup groupWithLabel:@"ZMTransportRequest task creation handler"];

    // TODO Alexis: do not execute if creationActivity is nil

    for (ZMTaskCreatedHandler *handler in self.taskCreatedHandlers) {
        id<ZMSGroupQueue> queue = handler.groupQueue;
        [handlerGroup enter];
        if (nil != queue) {
            [queue performGroupedBlock:^{
                ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:6 label:label];
                handler.block(taskIdentifier);
                [tp warnIfLongerThanInterval];
                [handlerGroup leave];
            }];
        }
    }    
}

- (void)addCompletionHandler:(ZMCompletionHandler *)completionHandler;
{
    VerifyReturn(completionHandler != nil);
    if (self.completionHandlers == nil) {
        self.completionHandlers = [NSMutableArray arrayWithObject:completionHandler];
    } else {
        [self.completionHandlers addObject:completionHandler];
    }
}

- (void)addProgressHandler:(ZMTaskProgressHandler *)progressHandler;
{
    VerifyReturn(progressHandler != nil);
    if (self.progressHandlers == nil) {
        self.progressHandlers = [NSMutableArray arrayWithObject:progressHandler];
    } else {
        [self.progressHandlers addObject:progressHandler];
    }
}

- (void)completeWithResponse:(ZMTransportResponse *)response
{
    RequireString(response.apiVersion == self.apiVersion, "Completed request and response should have matching api versions. Request has: %ld Response has: %d", (long)self.apiVersion, response.apiVersion);
    response.startOfUploadTimestamp = self.startOfUploadTimestamp;

    ZMSDispatchGroup *group = response.dispatchGroup;
    ZMSDispatchGroup *group2 = [ZMSDispatchGroup groupWithLabel:@"ZMTransportRequest"];
    [group2 enter];
    for(ZMCompletionHandler *handler in self.completionHandlers) {
        id<ZMSGroupQueue> queue = handler.groupQueue;
        if (queue != nil) {
            if (group) {
                [group enter];
            }
            [group2 enter];
            [queue performGroupedBlock:^{
                NSString *label = [NSString stringWithFormat:@"Completion handler of REQ %@ %@ -> %@ ",
                                   self.methodAsString,
                                   self.path,
                                   @(response.HTTPStatus)
                                   ];
                ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:6 label:label];
                handler.block(response);
                [tp warnIfLongerThanInterval];
                if (group) {
                    [group leave];
                }
                [group2 leave];
            }];
        }
    }
    [group2 leave];
    [group2 notifyOnQueue:dispatch_get_main_queue() block:^{
        if (self.activity) {
            [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:self.activity];
        }
    }];
}

- (void)updateProgress:(float)progress
{
    float limitedProgress = progress;
    if (limitedProgress > 1.0f) {
        limitedProgress = 1.0f;
    }
    if (limitedProgress < 0.0f) {
        limitedProgress = 0.0f;
    }
    
    self.progress = limitedProgress;
    
    for (ZMTaskProgressHandler *progresHandler in self.progressHandlers) {
        id<ZMSGroupQueue> queue = progresHandler.groupQueue;
        if (queue != nil) {
            [queue performGroupedBlock:^{
                progresHandler.block(limitedProgress);
            }];
        }
    }
}


- (BOOL)shouldUseOnlyBackgroundSession
{
    return self.transportSessionType == ZMTransportRequestSessionTypeUseBackgroundSessionOnly;
}

- (BOOL)shouldUseVoipSession
{
    return self.transportSessionType == ZMTransportRequestSessionTypeUseVoipSessionOnly;
}


- (void)forceToBackgroundSession
{
    self.transportSessionType = ZMTransportRequestSessionTypeUseBackgroundSessionOnly;
}

- (void)forceToVoipSession;
{
    self.transportSessionType = ZMTransportRequestSessionTypeUseVoipSessionOnly;
}

- (NSString *)completionHandlerDescription;
{
    return [NSString stringWithFormat:@"%@ %@", self.methodAsString, self.path];
}

- (BOOL)isEqualToRequest:(ZMTransportRequest *)request
{
    if (self == request) {
        return YES;
    }
    if (request == nil) {
        return NO;
    }
    return ((self.payload == request.payload || [self.payload isEqual:request.payload]) &&
            (self.path == request.path || [self.path isEqualToString:request.path]) &&
            (self.method == request.method) &&
            (self.acceptedResponseMediaTypes == request.acceptedResponseMediaTypes) &&
            (self.responseWillContainAccessToken == request.responseWillContainAccessToken) &&
            (self.responseWillContainCookie == request.responseWillContainCookie));
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p>", [self class], self];
    [description appendFormat:@" \"%@\"", self.methodAsString];
    if (self.path) {
        [description appendFormat:@" path \"%@\"", self.path];
    }
    
    [description appendFormat:@" %lu completionHandler(s)", (unsigned long)self.completionHandlers.count];
    
    if (self.payload) {
        NSDictionary *payload = (NSDictionary*)self.payload;
        if([payload isKindOfClass:[NSDictionary class]] && [payload objectForKey:@"password"] != nil) {
            NSMutableDictionary *mutablePayload = payload.mutableCopy;
            mutablePayload[@"password"] = @"<redacted>";
            payload = mutablePayload;
        }
        [description appendFormat:@" payload: %@", payload];
    }
    if (self.binaryData) {
        [description appendFormat:@" binary data: %llu", (unsigned long long) self.binaryData.length];
    }
    
    for (ZMMultipartBodyItem *bodyItem in self.multipartBodyItems) {
        [description appendString:[NSString stringWithFormat:@"\n----\nBody item: \n%@", bodyItem.description]];
    }
    
    if (self.debugInformation.count > 0) {
        [description appendString:@"\n"];
        for(NSString *info in self.debugInformation) {
            [description appendString:info];
            [description appendString:@"\n"];
        }
    }
    
    return description;
}

- (NSUInteger)hash
{
    NSUInteger hash = [self.payload hash];
    hash = hash * 31u + [self.path hash];
    hash = hash * 31u + [self.methodAsString hash];
    return hash;
}

+ (ZMTransportRequestMethod)methodFromString:(NSString *)string
{
    if([string isEqualToString:@"GET"]) {
        return ZMMethodGET;
    }
    if([string isEqualToString:@"POST"]) {
        return ZMMethodPOST;
    }
    if([string isEqualToString:@"DELETE"]) {
        return ZMMethodDELETE;
    }
    if([string isEqualToString:@"PUT"]) {
        return ZMMethodPUT;
    }
    if([string isEqualToString:@"HEAD"]) {
        return ZMMethodHEAD;
    }

    RequireString(false, "Invalid HTTP method string");
    return ZMMethodGET;
}

+ (NSString *)stringForMethod:(ZMTransportRequestMethod)method
{
    if(method == ZMMethodGET) {
        return @"GET";
    }
    if(method == ZMMethodPOST) {
        return @"POST";
    }
    if(method == ZMMethodDELETE) {
        return @"DELETE";
    }
    if(method == ZMMethodPUT) {
        return @"PUT";
    }
    if(method == ZMMethodHEAD) {
        return @"HEAD";
    }
    
    RequireString(false, "Invalid HTTP method: %lu", (unsigned long) method);
    return @"GET";
}

- (void)startBackgroundActivity 
{
    if (self.activity != nil) {
        return;
    }
    // Requests on background sessions will happen on their own, no need to keep the app running
    if (self.shouldUseOnlyBackgroundSession) {
        return;
    }
    NSString *activityName = [NSString stringWithFormat:@"Network request: %@ %@", self.methodAsString, self.path];
    self.activity = [[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:activityName];
}

@end


@implementation ZMTransportRequest (AssetGet)

+ (instancetype)assetGetRequestFromPath:(NSString *)path assetToken:(NSString *)token apiVersion:(int)apiVersion;
{
    ZMTransportRequest *r = [self requestGetFromPath:path apiVersion:apiVersion];
    
    if (nil != token) {
        [r addValue:token forAdditionalHeaderField:@"Asset-Token"];
    }
    
    Require(r.hasRequiredPayload);
    return r;
}

@end


@implementation ZMTransportRequest (ImageUpload)

+ (instancetype)postRequestWithPath:(NSString *)path imageData:(NSData *)data contentDisposition:(NSDictionary *)contentDisposition apiVersion:(int)apiVersion;
{
    VerifyReturnNil(data != nil);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    VerifyReturnNil(source != NULL);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    CFRelease(source);
    if (! [UTIHelper conformsToImageTypeWithUti:type]) {
        return nil;
    }
    ZMTransportRequest *result = [[self alloc] initWithPath:path method:ZMMethodPOST binaryData:data type:type contentDisposition:contentDisposition apiVersion:apiVersion];
    Require(result.hasRequiredPayload);
    return result;
}

+ (instancetype)multipartRequestWithPath:(NSString *)path imageData:(NSData *)imageData metaData:(NSDictionary *)metaData apiVersion:(int)apiVersion
{
    VerifyReturnNil(imageData != nil);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    VerifyReturnNil(source != NULL);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    NSString *mediaType = [UTIHelper convertToMimeWithUti:type];
    CFRelease(source);

    if (! [UTIHelper conformsToImageTypeWithUti:type]) {
        return nil;
    }

    return [self multipartRequestWithPath:path imageData:imageData metaData:metaData mediaContentType:mediaType apiVersion:apiVersion];
}

+ (instancetype)multipartRequestWithPath:(NSString *)path imageData:(NSData *)imageData metaData:(NSDictionary *)metaData mediaContentType:(NSString *)mediaContentType apiVersion:(int)apiVersion
{
    NSData *metaDataData = [NSJSONSerialization dataWithJSONObject:metaData options:0 error:NULL];
    return [self multipartRequestWithPath:path imageData:imageData metaData:metaDataData metaDataContentType:@"application/json; charset=utf-8" mediaContentType:mediaContentType apiVersion:apiVersion];
}

+ (instancetype)multipartRequestWithPath:(NSString *)path imageData:(NSData *)imageData metaData:(NSData *)metaData metaDataContentType:(NSString *)metaDataContentType mediaContentType:(NSString *)mediaContentType apiVersion:(int)apiVersion;
{
    VerifyReturnNil(imageData != nil);
    
    NSString *boundary = @"frontier";
    NSString *contentType = [NSString stringWithFormat:@"multipart/mixed; boundary=%@", boundary];
    NSData *multipartData = [self multipartDataWithImageData:imageData
                                                    metaData:metaData
                                         metaDataContentType:metaDataContentType
                                                   mediaType:mediaContentType
                                                    boundary:boundary];
    
    ZMTransportRequest *result = [[self alloc] initWithPath:path
                                                     method:ZMMethodPOST
                                                 binaryData:multipartData
                                                       type:contentType
                                         contentDisposition:nil
                                                 apiVersion:apiVersion];
    Require(result.hasRequiredPayload);
    return result;
}

+ (NSData *)multipartDataWithImageData:(NSData *)imageData metaData:(NSData *)metaData metaDataContentType:(NSString *)metaDataContentType mediaType:(NSString *)mediaType boundary:(NSString *)boundary
{
    ZMMultipartBodyItem *metaDataBodyItem = [[ZMMultipartBodyItem alloc] initWithData:metaData
                                                                          contentType:metaDataContentType
                                                                              headers:nil];
    
    ZMMultipartBodyItem *imageBodyItem = [[ZMMultipartBodyItem alloc] initWithData:imageData
                                                                       contentType:mediaType
                                                                           headers:@{
                                                                                     @"Content-MD5": [[imageData zmMD5Digest] base64EncodedStringWithOptions:0]
                                                                                     }];
    
    return [NSData multipartDataWithItems:@[metaDataBodyItem, imageBodyItem] boundary:boundary];
}

- (NSArray *)multipartBodyItems
{
    if ([self.binaryDataType hasPrefix:@"multipart/mixed"]) {
        NSString *boundary = [[self.binaryDataType componentsSeparatedByString:@";"] lastObject];
        boundary = [[boundary componentsSeparatedByString:@"="] lastObject];
        return [self.binaryData multipartDataItemsSeparatedWithBoundary:boundary];
    }
    else {
        return nil;
    }
}

@end



@implementation ZMTransportRequest (Debugging)

- (void)setDebugInformationTranscoder:(NSObject *)transcoder;
{
    [self.debugInformation addObject:[NSString stringWithFormat:@"Transcoder: <%@> %p", NSStringFromClass(transcoder.class), transcoder]];
}

- (void)setDebugInformationState:(NSObject *)state;
{
    [self.debugInformation addObject:[NSString stringWithFormat:@"Sync state: <%@> %p", NSStringFromClass(state.class), state]];
}

- (void)addContentDebugInformation:(NSString *)debugInformation
{
    [self.debugInformation addObject:debugInformation];
    self.contentDebugInformationHash ^= debugInformation.hash;
}

- (void)markStartOfUploadTimestamp {
    self.startOfUploadTimestamp = [NSDate date];
}

@end
