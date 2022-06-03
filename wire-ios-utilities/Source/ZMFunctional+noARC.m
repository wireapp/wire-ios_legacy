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


#import "ZMFunctional.h"

#if __has_feature(objc_arc)
#error This file cannot be compiled with ARC. Add -fno-objc-arc as a compiler flag
#endif


@implementation NSArray (ZMFunctional_withoutARC)

- (NSArray *)mapWithSelector:(SEL)selector;
{
    NSMutableArray *result = [NSMutableArray array];
    for (id obj in self) {
        @autoreleasepool {
            id newObj = [obj performSelector:selector];
            if (newObj != nil) {
                [result addObject:newObj];
            }
        }
    }
    return result;
}

- (id)firstNonNilReturnedFromSelector:(SEL)selector;
{
    for(id obj in self) {
        if(obj && obj != [NSNull null]) {
            id result = [obj performSelector:selector];
            if(result != nil) {
                return result;
            }
        }
    }
    return nil;
}

@end



@implementation NSOrderedSet (ZMFunctional_withoutARC)

- (NSOrderedSet *)mapWithSelector:(SEL)selector;
{
    NSMutableOrderedSet *result = [NSMutableOrderedSet orderedSet];
    for (id obj in self) {
        @autoreleasepool {
            id newObj = [obj performSelector:selector];
            if (newObj != nil) {
                [result addObject:newObj];
            }
        }
    }
    return result;
}

@end
