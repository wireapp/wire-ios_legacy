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


#import "NetworkStatus.h"

@import WireSystem;

// helpers
#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

static NSString* ZMLogTag ZM_UNUSED = @"UI";
static NSString *NetworkStatusNotificationName = @"NetworkStatusNotification";
void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info);



@interface NetworkStatus ()

@property (nonatomic, unsafe_unretained) SCNetworkReachabilityRef reachabilityRef;

@end



@implementation NetworkStatus


#pragma mark - NSObject

- (instancetype)initWithHost:(NSURL *)hostURL
{
    self = [super init];
    if (self) {
        #ifndef __clang_analyzer__
        self.reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, hostURL.host.UTF8String);
        #endif
        [self startReachabilityObserving];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        #ifndef __clang_analyzer__
        self.reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
        #endif
        [self startReachabilityObserving];
    }
    return self;
}

- (void)dealloc
{
    if (self.reachabilityRef != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(self.reachabilityRef);
    }
}

- (void)startReachabilityObserving
{
    if (self.reachabilityRef != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        
        if (SCNetworkReachabilitySetCallback(self.reachabilityRef, ReachabilityCallback, &context)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
                ZMLogInfo(@"Scheduled network reachability callback in runloop");
            } else {
                ZMLogError(@"Error scheduling network reachability in runloop");
            }
        } else {
            ZMLogError(@"Error setting network reachability callback");
        }
    }
}

#pragma mark - Public API

+ (instancetype)statusForHost:(NSURL *)hostURL
{
    NetworkStatus *status = [[NetworkStatus alloc] initWithHost:hostURL];
    return status;
}

+ (instancetype)sharedStatus
{
    static NetworkStatus *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (ServerReachability)reachability
{
    NSAssert(self.reachabilityRef != NULL, @"reachability getter called with NULL reachabilityRef");
    ServerReachability returnValue = ServerReachabilityUnreachable;
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        
        BOOL reachable = (flags & kSCNetworkReachabilityFlagsReachable);
        BOOL connectionRequired = (flags & kSCNetworkReachabilityFlagsConnectionRequired);
        
        if (reachable && ! connectionRequired)  {
            ZMLogInfo(@"Reachability status: reachable and connected.");
            returnValue = ServerReachabilityOK;
            
        }
        else if (reachable && connectionRequired) {
            ZMLogInfo(@"Reachability status: reachable but connection required.");
        }
        else {
            ZMLogInfo(@"Reachability status: not reachable.");
        }
    }
    else {
        ZMLogInfo(@"Reachability status could not be determined.");
    }
    return returnValue;
}

+ (void)addNetworkStatusObserver:(id<NetworkStatusObserver>)observer
{
    // Make sure that we have an actual instance doing the monitoring, whenever someone asks for it
    [self sharedStatus];
    
    [[NSNotificationCenter defaultCenter] addObserver:observer
                                             selector:@selector(wr_networkStatusDidChange:)
                                                 name:NetworkStatusNotificationName
                                               object:nil];
}

+ (void)removeNetworkStatusObserver:(id<NetworkStatusObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:NetworkStatusNotificationName
                                                  object:nil];
}

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (BOOL)isNetworkQualitySufficientForOnlineFeatures
{
    
    BOOL goodEnough = YES;
    BOOL isWifi = YES;
    
    if(self.reachability == ServerReachabilityOK){
        // we are online, check if we are on wifi or not
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags);
        
        isWifi = !(flags & kSCNetworkReachabilityFlagsIsWWAN);
    }
    else {
        // we are offline, so access is definitetly not good enough
        goodEnough = NO;
        return goodEnough;
    }
    
    
    if(!isWifi)
    {
        // we are online, but we determited from above that we're on radio
        CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        
        NSString *radioAccessTechnology = networkInfo.currentRadioAccessTechnology;
        
        if([radioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS] || [radioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]){
            
            goodEnough = NO;
        }
    }
    
    return goodEnough;
}
#endif

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> Server reachability: %@",
            [self class],
            self,
            [self stringForCurrentStatus]];
}



#pragma mark - Utilities

void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [NetworkStatus class]], @"info was wrong class in ReachabilityCallback");
    
    NetworkStatus* noteObject = (__bridge NetworkStatus *)info;
    // Post a notification to notify the client that the network reachability changed.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NetworkStatusNotificationName object:noteObject];
}

- (NSString *)stringForCurrentStatus
{
    if (self.reachability == ServerReachabilityOK) {
        return @"OK";
    }
    return @"Unreachable";
}

@end
