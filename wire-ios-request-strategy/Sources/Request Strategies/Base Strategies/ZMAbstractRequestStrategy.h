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

#import "ZMStrategyConfigurationOption.h"
#import "RequestStrategy.h"

@class ZMTransportRequest;
@class NSManagedObjectContext;
@protocol ZMApplicationStatus;

@interface ZMAbstractRequestStrategy : NSObject <RequestStrategy>

@property (nonatomic, readonly, nonnull) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) ZMStrategyConfigurationOption configuration;
@property (nonatomic, readonly, nonnull) id<ZMApplicationStatus> applicationStatus;

- (instancetype _Nonnull)initWithManagedObjectContext:(nonnull NSManagedObjectContext *)managedObjectContext applicationStatus:(nonnull id<ZMApplicationStatus>)applicationStatus;

- (ZMTransportRequest * _Nullable)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion;

@end
