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


#import "ZMWebSocketHandshake.h"
#import <WireTransport/WireTransport-Swift.h>

@import WireSystem;



const NSUInteger MAX_LINE_LENGTH = 256;
static NSString * const ZMWebSocketHandshakeErrorDomain = @"ZMWebSocketHandshake";



@interface ZMWebSocketHandshake ()

@property (nonatomic) DataBuffer *buffer;
@property (nonatomic) NSHTTPURLResponse *response;

@end




@implementation ZMWebSocketHandshake

- (instancetype)initWithDataBuffer:(DataBuffer *)buffer;
{
    self = [super init];
    if (self) {
        self.buffer = buffer;
    }
    return self;
}


- (ZMWebSocketHandshakeResult)parseAndClearBufferIfComplete:(BOOL)clear error:(NSError * __autoreleasing *)error;
{
    if (error) {
        *error = nil;
    }
    NSData *entireData = (id) self.buffer.objcData;
    static NSUInteger const MaxResponseLength = 500;
    NSUInteger const length = MIN(entireData.length, MaxResponseLength);
    NSRange responseRange = [entireData rangeOfData:[NSData dataWithBytes:"\r\n\r\n" length:4] options:0 range:NSMakeRange(0, length)];

    if (responseRange.length == 0) {
        if (length == MaxResponseLength) {
            if (error) {
                *error = [NSError errorWithDomain:ZMWebSocketHandshakeErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Response did not end within range."}];
            }
            return ZMWebSocketHandshakeError;
        } else {
            return ZMWebSocketHandshakeNeedsMoreData;
        }
    }

    NSInteger statusCode;
    NSDictionary *allHeaderFields;
    NSString *httpVersion;
    
    {
        NSData *responseData = [entireData subdataWithRange:NSMakeRange(0, NSMaxRange(responseRange))];
        CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(NULL, NO);
        if (message == NULL) {
            return ZMWebSocketHandshakeError;
        }
        if (! CFHTTPMessageAppendBytes(message, responseData.bytes, (CFIndex) responseData.length)) {
            CFRelease(message);
            return ZMWebSocketHandshakeError;
        }
        
        
        const BOOL isHeaderComplete = CFHTTPMessageIsHeaderComplete(message) == 1u;
        
        if(! isHeaderComplete) {
            CFRelease(message);
            return ZMWebSocketHandshakeNeedsMoreData;
        }
        
        statusCode = CFHTTPMessageGetResponseStatusCode(message);
        allHeaderFields = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(message));
        httpVersion = CFBridgingRelease(CFHTTPMessageCopyVersion(message));
        CFRelease(message);
    }
    
    if ((allHeaderFields != nil) && (httpVersion != nil)) {
        NSURL *URL = [NSURL URLWithString:@"https://example.com"];
        self.response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:statusCode HTTPVersion:httpVersion headerFields:allHeaderFields];
    }
    
    if (statusCode != 101) {
        if (error) {
            *error = [NSError errorWithDomain:ZMWebSocketHandshakeErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Status code is not 101"}];
        }
        return ZMWebSocketHandshakeError;
    }
    
    NSDictionary *expectedHeaders = @{@"Connection": @"upgrade",
                                      @"Upgrade": @"websocket"};

    __block BOOL allHeadersPresent = YES;
    __block BOOL wrongHeaderContent = NO;
    __block NSError *headerError;
    [expectedHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *expectedValue, BOOL *stop){
        NSString *value = allHeaderFields[field];
        if(value == nil) {
            if (error) {
                NSString *errDesc = [NSString stringWithFormat:@"Missing header field value -> %@ (expected %@)", field, expectedValue];
                headerError = [NSError errorWithDomain:ZMWebSocketHandshakeErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: errDesc}];
            }
            allHeadersPresent = NO;
            *stop = YES;
            return;
        }
        
        if (! [[value lowercaseString] isEqualToString:expectedValue]) {
            if (error) {
                NSString *errDesc = [NSString stringWithFormat:@"Wrong header field value -> %@ : %@ (expected %@)", field, value, expectedValue];
                headerError = [NSError errorWithDomain:ZMWebSocketHandshakeErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: errDesc}];
            }
            wrongHeaderContent = YES;
            *stop = YES;
            return;
        }
    }];
    
    if (wrongHeaderContent) {
        if(error) {
            *error = headerError;
        }
        return ZMWebSocketHandshakeError;
    }
    
    if (allHeadersPresent) {
        if(clear) {
            [self.buffer clearUntil:(int)NSMaxRange(responseRange)];
        }
        return ZMWebSocketHandshakeCompleted;
    }

    if (error) {
        *error = headerError;
    }
    return ZMWebSocketHandshakeError;
}


- (BOOL)isAnyLineIn:(NSArray *)bufferLines longerThan:(NSUInteger)maxLength;
{
    for (NSString *string in bufferLines) {
        if (string.length > maxLength) {
            return YES;
        }
    }
    
    return NO;
}


- (BOOL)doesHeader:(NSArray *)receivedHeader startWithLines:(NSArray *)expectedLines error:(NSError **)error {
    
    for (NSString *string in expectedLines) {
        NSString *expectedString = [string lowercaseString];
        NSUInteger index = [receivedHeader indexOfObject:expectedString];
        BOOL headerLineIsOutsideHeader = index >= expectedLines.count;
        if (receivedHeader.count >= expectedLines.count && headerLineIsOutsideHeader) {
            if (error) {
                *error = [NSError errorWithDomain:@"ZMWebSocketHandshake" code:3 userInfo:nil];
            }
            return NO;
        }
        
        if (index == NSNotFound) {
            return NO;
        }
    }
    
    return YES;
}


@end
