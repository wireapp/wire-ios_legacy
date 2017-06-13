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


#import "AnalyticsEvent.h"
#import "DefaultIntegerClusterizer.h"
#import "objc/runtime.h"

static dispatch_queue_t currentMetaAccessQ = NULL;
static NSMapTable *currentMeta = nil;



@implementation AnalyticsEvent

+ (void)load
{
    @autoreleasepool {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            currentMetaAccessQ = dispatch_queue_create("CurrentMetaAccessQ", DISPATCH_QUEUE_SERIAL);
            currentMeta = [NSMapTable strongToStrongObjectsMapTable];
        });
    }
}

+ (instancetype)currentMeta
{
    __block AnalyticsEvent *current = nil;
    dispatch_sync(currentMetaAccessQ, ^{
        current = [currentMeta objectForKey:self.class];

        if (current == nil) {
            current = [self.class new];
            [currentMeta setObject:current forKey:self.class];
        }
    });

    return current;
}

+ (void)resetCurrentMeta
{
    dispatch_sync(currentMetaAccessQ, ^{
        if (currentMeta != nil) {
            [currentMeta removeObjectForKey:self.class];
        }
    });
}

- (NSDictionary *)attributesDump
{
    NSAssert(NO, @"attempting to invoke method on abstract implementation");
    return nil;
}

- (NSString *)eventTag
{
    NSAssert(NO, @"attempting to invoke method on abstract implementation");
    return nil;
}

- (NSNumber *)customerValueIncrease
{
    return nil;
}

- (void)dumpIntegerClusterizedValueForKey:(NSString *)key toDictionary:(NSMutableDictionary *)dict
{
    [self dumpIntegerClusterizedValueForKey:key toDictionary:dict forClusterizer:DefaultIntegerClusterizer.defaultClusterizer];
}

- (void)dumpIntegerClusterizedValueForKey:(NSString *)key toDictionary:(NSMutableDictionary *)dict forClusterizer:(DefaultIntegerClusterizer *)clusterizer
{
    if (key == nil) {
        return;
    }

    NSNumber *value = [self valueForKey:key];
    if (! [value isKindOfClass:[NSNumber class]]) {
        return;
    }
    
    [dict setObject:[clusterizer clusterizeInteger:[value integerValue]]
             forKey:[NSString stringWithFormat:@"%@_clusterized", key]];
    
    [dict setObject:value forKey:key];
}

@end
