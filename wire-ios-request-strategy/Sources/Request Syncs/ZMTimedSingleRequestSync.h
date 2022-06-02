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
#import <WireRequestStrategy/ZMSingleRequestSync.h>

@class ZMTransportRequest;
@protocol ZMSGroupQueue;

@interface ZMTimedSingleRequestSync : ZMSingleRequestSync

/// setting this stops the current timer
@property (nonatomic) NSTimeInterval timeInterval;


- (instancetype)initWithSingleRequestTranscoder:(id<ZMSingleRequestTranscoder>)transcoder
                                     groupQueue:(id<ZMSGroupQueue>)groupQueue NS_UNAVAILABLE;

- (instancetype)initWithSingleRequestTranscoder:(id<ZMSingleRequestTranscoder>)transcoder
                              everyTimeInterval:(NSTimeInterval) timeInterval
                                     groupQueue:(id<ZMSGroupQueue>)groupQueue NS_DESIGNATED_INITIALIZER;

/// cancels the timer and stop returning requests
- (void)invalidate;

@end
