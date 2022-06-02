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
#import "ZMReachability.h"
#import "ZMPushChannel.h"
#import "ZMPushChannelType.h"

@class ZMTransportRequestScheduler;
@class ZMAccessToken;
@protocol ZMPushChannelConsumer;
@protocol ZMSGroupQueue;
@protocol ZMReachabilityObserver;
@protocol BackendEnvironmentProvider;


/// This class is responsible for opening and closing the push channel connection to the backend.
@interface ZMTransportPushChannel : NSObject <ZMReachabilityObserver, ZMPushChannel, ZMPushChannelType>

@property (nonatomic, weak, nullable) id <ZMNetworkStateDelegate> networkStateDelegate;

- (instancetype _Nonnull )initWithScheduler:(ZMTransportRequestScheduler * _Nonnull)scheduler
                            userAgentString:(NSString * _Nonnull)userAgentString
                                environment:(id <BackendEnvironmentProvider> _Nonnull)environment
                                      queue:(NSOperationQueue * _Nonnull)queue;
- (instancetype _Nonnull )initWithScheduler:(ZMTransportRequestScheduler * _Nonnull)scheduler
                  userAgentString:(NSString * _Nonnull)userAgentString
                      environment:(id <BackendEnvironmentProvider> _Nonnull)environment
                           pushChannelClass:(Class _Nullable )pushChannelClass NS_DESIGNATED_INITIALIZER;

@end
