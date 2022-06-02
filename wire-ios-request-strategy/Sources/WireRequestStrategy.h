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

#import <UIKit/UIKit.h>

//! Project version number for WireRequestStrategy.
FOUNDATION_EXPORT double WireRequestStrategyVersionNumber;

//! Project version string for WireRequestStrategy.
FOUNDATION_EXPORT const unsigned char WireRequestStrategyVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WireRequestStrategy/PublicHeader.h>

#import <WireRequestStrategy/ZMObjectSyncStrategy.h>
#import <WireRequestStrategy/ZMContextChangeTracker.h>
#import <WireRequestStrategy/ZMRequestGenerator.h>
#import <WireRequestStrategy/ZMOutstandingItems.h>
#import <WireRequestStrategy/ZMDownstreamObjectSync.h>
#import <WireRequestStrategy/ZMDownstreamObjectSyncWithWhitelist.h>
#import <WireRequestStrategy/ZMLocallyInsertedObjectSet.h>
#import <WireRequestStrategy/ZMLocallyModifiedObjectSet.h>
#import <WireRequestStrategy/ZMLocallyModifiedObjectSyncStatus.h>
#import <WireRequestStrategy/ZMRemoteIdentifierObjectSync.h>
#import <WireRequestStrategy/ZMSingleRequestSync.h>
#import <WireRequestStrategy/ZMSyncOperationSet.h>
#import <WireRequestStrategy/ZMTimedSingleRequestSync.h>
#import <WireRequestStrategy/ZMUpstreamInsertedObjectSync.h>
#import <WireRequestStrategy/ZMUpstreamModifiedObjectSync.h>
#import <WireRequestStrategy/ZMupstreamRequest.h>
#import <WireRequestStrategy/ZMUpstreamTranscoder.h>
#import <WireRequestStrategy/ZMChangeTrackerBootstrap.h>
#import <WireRequestStrategy/ZMChangeTrackerBootstrap+Testing.h>
#import <WireRequestStrategy/ZMImagePreprocessingTracker.h>
#import <WireRequestStrategy/ZMImagePreprocessingTracker+Testing.h>
#import <WireRequestStrategy/ZMStrategyConfigurationOption.h>
#import <WireRequestStrategy/ZMAbstractRequestStrategy.h>
#import <WireRequestStrategy/RequestStrategy.h>
#import <WireRequestStrategy/ZMSimpleListRequestPaginator.h>

