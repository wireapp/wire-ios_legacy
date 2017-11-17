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



@class NetworkStatus;



typedef NS_ENUM(NSInteger, ServerReachability) {
    
    /// Backend can be reached.
    ServerReachabilityOK,
    
    /// Backend can not be reached.
    ServerReachabilityUnreachable
};



@protocol NetworkStatusObserver <NSObject>

/// note.object is the NetworkStatus instance doing the monitoring.
/// Method name @c `-networkStatusDidChange:` conflicts with some apple internal method name.
- (void)wr_networkStatusDidChange:(NSNotification *)note;

@end



/// This class monitors the reachability of backend. It emits notifications to its observers if the status changes.
@interface NetworkStatus : NSObject

/// Returns status for specific host
+ (instancetype)statusForHost:(NSURL *)hostURL;

/// The shared network status object (status of 0.0.0.0)
+ (instancetype)sharedStatus;

//- (id)initWithClientInstance:(ZCClientInstance *)clientInstance;

/// Current state of the network.
- (ServerReachability)reachability;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
// This indicates if the network quality according to the system is at 3G level or above. On Wifi it will return YES.
// When offline it will return NO;
- (BOOL)isNetworkQualitySufficientForOnlineFeatures;
#endif

- (NSString *)stringForCurrentStatus;

+ (void)addNetworkStatusObserver:(id<NetworkStatusObserver>)observer;
+ (void)removeNetworkStatusObserver:(id<NetworkStatusObserver>)observer;

@end



/// Convenience shortcut
static inline BOOL IsNetworkReachable() {
    return ([NetworkStatus sharedStatus].reachability == ServerReachabilityOK);
}
