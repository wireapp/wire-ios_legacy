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
#import <WireRequestStrategy/WireRequestStrategy-Swift.h>
#import "ZMAbstractRequestStrategy.h"

static NSString* ZMLogTag ZM_UNUSED = @"Request Configuration";

@implementation ZMAbstractRequestStrategy

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext applicationStatus:(id<ZMApplicationStatus>)applicationStatus
{
    self = [super init];
    
    if (self != nil) {
        _managedObjectContext = managedObjectContext;
        _applicationStatus = applicationStatus;
    }
    
    return self;
}

/// Subclasses should override this method
- (ZMTransportRequest *)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion
{
    [NSException raise:NSInvalidArgumentException format:@"You must subclass nextRequestIfAllowed"];
    return nil;
}

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    if ([self configuration:self.configuration isSubsetOfPrerequisites:[AbstractRequestStrategy prerequisitesForApplicationStatus:self.applicationStatus]]) {
        return [self nextRequestIfAllowedForAPIVersion:apiVersion];
    }
    
    return nil;
}

- (BOOL)configuration:(ZMStrategyConfigurationOption)configuration isSubsetOfPrerequisites:(ZMStrategyConfigurationOption)prerequisites
{
    ZMStrategyConfigurationOption option = 0;
    
    for (NSUInteger index = 0; option <= ZMStrategyConfigurationOptionAllowsRequestsDuringQuickSync; index++) {
        option = 1 << index;
        
        if ((prerequisites & option) == option && (configuration & option) != option) {
            ZMLogDebug(@"Not performing requests since option: %lu is not configured for (%@)", (unsigned long)option, NSStringFromClass(self.class));
            return NO;
        }
    }
    
    return YES;
}

@end
