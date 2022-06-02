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

NS_ASSUME_NONNULL_BEGIN

@interface NSError (ZMTransportSession)

- (BOOL)isCancelledURLTaskError;
- (BOOL)isTimedOutURLTaskError;
- (BOOL)isURLTaskNetworkError;

+ (NSError *)requestExpiredError;
+ (NSError *)tryAgainLaterError;
+ (NSError *)tryAgainLaterErrorWithUserInfo:(nullable NSDictionary *)userInfo;


/// @c YES if the request what cancelled
@property (nonatomic, readonly) BOOL isExpiredRequestError;

/// If @c YES the request should be re-enqueued at a later point in time.
///
/// If the sender can re-enqueue the error (e.g. ZMUpstreamModifiedObjectSync et al.) it should reset the state for the corresponding object.
/// If the sender can @e not re-enqueue if should assume that the request failed.
@property (nonatomic, readonly) BOOL isTryAgainLaterError;


+ (nullable NSError *)transportErrorFromURLTask:(NSURLSessionTask *)task expired:(BOOL)expired;

@end

NS_ASSUME_NONNULL_END
