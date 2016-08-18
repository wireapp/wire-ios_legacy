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
#import "AnalyticsProvider.h"
#import <zmessaging/zmessaging.h>

@class AnalyticsSessionSummaryEvent;
@class AnalyticsRegistration;
@class AnalyticsEvent;



typedef NS_ENUM (NSUInteger, AnalyticsEventSource) {
    AnalyticsEventSourceUnspecified,
    AnalyticsEventSourceUI,
    AnalyticsEventSourceMenu,
    AnalyticsEventSourceShortcut
};


/// A simple vendor-independent interface to tracking analytics from the UIs.
@interface Analytics : NSObject <AnalyticsType>

/// Disable any analytics logging (different from opting out)
@property (nonatomic, assign) BOOL disabled;

/// Opt the user out of sending analytics data
@property (nonatomic, assign) BOOL isOptedOut;

@property (nonatomic, readonly) AnalyticsSessionSummaryEvent *sessionSummary;

/// For tagging registration events
@property (nonatomic, assign) BOOL observingConversationList;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithProvider:(id<AnalyticsProvider>)provider NS_DESIGNATED_INITIALIZER;

/// Record a screen (page view).
- (void)tagScreen:(NSString *)screen;

/// Record an event with no attributes
- (void)tagEvent:(NSString *)event;
- (void)tagEvent:(NSString *)event source:(AnalyticsEventSource)source;

/// Record an event with optional attributes.
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes;
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes source:(AnalyticsEventSource)source;

- (void)tagEventObject:(AnalyticsEvent *)event;
- (void)tagEventObject:(AnalyticsEvent *)event source:(AnalyticsEventSource)source;

/// Close the current session and store metadata to disk
- (void)close;

/// Resume the current session and restore metadata if the session hasn't expired
/// If the session is already open, this call will have no effect
- (void)resume;

/// Upload the tracked data
- (void)upload;

/// A short cut method for @c close and @c upload cause this combination is needed often
- (void)closeAndUpload;

/// Set the custom dimensions values
- (void)sendCustomDimensionsWithNumberOfContacts:(NSUInteger)contacts
                              groupConversations:(NSUInteger)groupConv
                                     accentColor:(NSInteger)accent
                                     networkType:(NSString *)networkType
                       notificationConfiguration:(NSString *)config;

@end



@interface Analytics (Push)

/// Typically called from @c application:didRegisterForRemoteNotificationsWithDeviceToken:
- (void)setPushToken:(NSData *)token;

/// Typically called from @c application:didReceiveRemoteNotification:fetchCompletionHandler:
- (void)handleRemoteNotification:(NSDictionary *)userInfo;

@end



@interface Analytics (OpenURL)

/// Typically called from @c application:openURL:sourceApplication:annotation:
- (BOOL)handleOpenURL:(NSURL *)url;

@end
