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


#import <WireTransport/ZMTransportRequest.h>


@interface ZMTransportRequest (Internal)

@property (nonatomic) NSMutableArray<ZMCompletionHandler *> *completionHandlers;
@property (nonatomic) NSMutableArray<ZMTaskProgressHandler *> *progressHandlers;

+ (NSString *)stringForMethod:(ZMTransportRequestMethod)method;
+ (ZMTransportRequestMethod)methodFromString:(NSString *)string;

- (void)setAdditionalHeaderFieldsOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
- (void)setAcceptedResponseMediaTypeOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
- (void)setBodyDataAndMediaTypeOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
- (void)setContentDispositionOnHTTPRequest:(NSMutableURLRequest *)URLRequest;
- (void)setTimeoutIntervalOnRequestIfNeeded:(NSMutableURLRequest *)request
                  applicationIsBackgrounded:(BOOL)inBackground
                     usingBackgroundSession:(BOOL)usingBackgroundSession;

/// This is intended for logs such that it does not reveal any payload
@property (nonatomic, readonly, copy) NSString *descriptionWithMethodAndPath;
@property (nonatomic, readonly) float progress;

- (void)startBackgroundActivity;

@end
