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

#import "AnalyticsProvider.h"

@import Foundation;
@import WireSyncEngine;

@class AnalyticsSessionSummaryEvent;
@class AnalyticsRegistration;
@class AnalyticsEvent;

typedef NS_ENUM (NSUInteger, AnalyticsEventSource) {
    AnalyticsEventSourceUnspecified,
    AnalyticsEventSourceUI,
    AnalyticsEventSourceMenu,
    AnalyticsEventSourceShortcut
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * MixpanelAPIKey;
FOUNDATION_EXPORT BOOL UseAnalytics;

/// A simple vendor-independent interface to tracking analytics from the UIs.
@interface Analytics : NSObject <AnalyticsType>

/// Opt the user out of sending analytics data
@property (nonatomic, assign) BOOL isOptedOut;

@property (nonatomic, readonly) AnalyticsSessionSummaryEvent *sessionSummary;

/// For tagging registration events
@property (nonatomic, assign) BOOL observingConversationList;

@property (nonatomic, nullable) Team* team;

+ (void)loadSharedWithOptedOut:(BOOL)optedOut;
+ (instancetype)shared;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOptedOut:(BOOL)optedOut NS_DESIGNATED_INITIALIZER;

/// Record an event with no attributes
- (void)tagEvent:(NSString *)event;
- (void)tagEvent:(NSString *)event source:(AnalyticsEventSource)source;
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes team:(nullable Team *)team;

/// Record an event with optional attributes.
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes;
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes source:(AnalyticsEventSource)source;

- (void)tagEventObject:(AnalyticsEvent *)event;
- (void)tagEventObject:(AnalyticsEvent *)event source:(AnalyticsEventSource)source;

/// Set the custom dimensions values
- (void)sendCustomDimensionsWithNumberOfContacts:(NSUInteger)contacts
                              groupConversations:(NSUInteger)groupConv;

@end

NS_ASSUME_NONNULL_END
