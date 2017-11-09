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
#import "DefaultIntegerClusterizer.h"


/// Abstract class for events that are more complex than just simple tags.
/// Tag the event by calling "tagEventObject"

@interface AnalyticsEvent : NSObject

/// Dump attributes with clusterization for upload to analytics server
- (NSDictionary *)attributesDump;

- (NSString *)eventTag;

- (void)dumpIntegerClusterizedValueForKey:(NSString *)key toDictionary:(NSMutableDictionary *)dict;
- (void)dumpIntegerClusterizedValueForKey:(NSString *)key toDictionary:(NSMutableDictionary *)dict forClusterizer:(DefaultIntegerClusterizer *)clusterizer;

@end
