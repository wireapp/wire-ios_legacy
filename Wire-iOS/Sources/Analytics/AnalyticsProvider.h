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


@protocol AnalyticsProvider <NSObject>

@property (nonatomic, assign) BOOL isOptedOut;

- (instancetype)initWithLaunchOptions:(NSDictionary *)launchOptions;

/// Record a screen (page view).
- (void)tagScreen:(NSString *)screen;

/// Record an event with no attributes
- (void)tagEvent:(NSString *)event;

/// Record an event with optional attributes.
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes;

/// Record an event with optional attributes and customer lifetime value increase
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes
    customerValueIncrease:(NSNumber *)customerValueIncrease;

/// Set a custom dimension-- this may be localytics specific
- (void)setCustomDimension:(int)dimension value:(NSString *)value;

@end
