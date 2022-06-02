//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

#import "MockReachability.h"

NSString * const ZMReachabilityChangedNotificationName = @"ZMReachabilityChangedNotification";

@interface MockReachability ()
@property (nonatomic) BOOL isReachable;
@property (nonatomic) BOOL isMobile;
@end

@implementation MockReachability

- (instancetype)init
{
    return [self initWithReachability:YES isMobileConnection:YES];
}

- (instancetype)initWithReachability:(BOOL)isReachable isMobileConnection:(BOOL)isMobileConnection
{
    self = [super init];
    if (self) {
        self.isReachable = isReachable;
        self.isMobile = isMobileConnection;
    }
    return self;
}

-(void)tearDown{
    //no-op
}

-(BOOL)mayBeReachable{
    return self.isReachable;
}

-(BOOL)oldMayBeReachable{
    return self.isReachable;
}

-(BOOL)isMobileConnection{
    return self.isMobile;
}

-(BOOL)oldIsMobileConnection{
    return self.isMobile;
}

-(id)addReachabilityObserver:(id<ZMReachabilityObserver>)observer queue:(NSOperationQueue *)queue{
    ZM_WEAK(observer);
    return [self addReachabilityObserverOnQueue:queue block:^(id<ReachabilityProvider> provider) {
        ZM_STRONG(observer);
        [observer reachabilityDidChange:provider];
    }];
}

-(id)addReachabilityObserverOnQueue:(NSOperationQueue *)queue block:(ReachabilityObserverBlock)block{
    ZM_WEAK(self);
    id token = [[NSNotificationCenter defaultCenter] addObserverForName:ZMReachabilityChangedNotificationName object:self queue:queue usingBlock:^(NSNotification * _Nonnull note) {
        NOT_USED(note);
        ZM_STRONG(self);
        block(self);
    }];
    
    return [[SelfUnregisteringNotificationCenterToken alloc] init:token];
}

@end
