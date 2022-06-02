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


#import "NSError+ZMTransportSession.h"
#import "ZMTransportSessionErrorCode.h"
#import "ZMTransportRequestScheduler.h"


NSString * const ZMTransportSessionErrorDomain = @"ZMTransportSession";



@implementation NSError (ZMTransportSession)


- (BOOL)isCancelledURLTaskError;
{
    return (self.code == NSURLErrorCancelled) && [self.domain isEqualToString:NSURLErrorDomain];
}
- (BOOL)isTimedOutURLTaskError;
{
    return (self.code == NSURLErrorTimedOut) && [self.domain isEqualToString:NSURLErrorDomain];
}
- (BOOL)isURLTaskNetworkError;
{
    return (self.code != NSURLErrorCancelled) && (self.code != NSURLErrorTimedOut) && [self.domain isEqualToString:NSURLErrorDomain];
}


+ (NSError *)requestExpiredError;
{
    return [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil];
}

+ (NSError *)tryAgainLaterError;
{
    return [self.class tryAgainLaterErrorWithUserInfo:nil];
}

+ (NSError *)tryAgainLaterErrorWithUserInfo:(NSDictionary *)userInfo;
{
    return [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:userInfo];
}


+ (NSError *)authenticationError;
{
    return [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeAuthenticationFailed userInfo:nil];
}

- (BOOL)isExpiredRequestError;
{
    return (self.code == ZMTransportSessionErrorCodeRequestExpired) && [self.domain isEqualToString:ZMTransportSessionErrorDomain];
}

- (BOOL)isTryAgainLaterError;
{
    return (self.code == ZMTransportSessionErrorCodeTryAgainLater) && [self.domain isEqualToString:ZMTransportSessionErrorDomain];
}


+ (NSError *)transportErrorFromURLTask:(NSURLSessionTask *)task expired:(BOOL)expired;
{
    NSError *urlError = task.error;
    if (urlError == nil) {
        // Check for 420 / 429 / internal server error
        NSInteger const statusCode = ((NSHTTPURLResponse *) task.response).statusCode;
        BOOL const isBackOff = ((statusCode == TooManyRequestsStatusCode) ||
                                (statusCode == EnhanceYourCalmStatusCode));
        BOOL const isInternalError = ((statusCode >= 500) &&
                                      (statusCode <= 599));
        if (!isBackOff && !isInternalError) {
            return nil;
        }
    } else if (urlError.isCancelledURLTaskError && expired) {
        return [NSError requestExpiredError];
    }
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Request finished with task error %@.", task.error.localizedDescription]};
    return [NSError tryAgainLaterErrorWithUserInfo:userInfo];
}

@end
