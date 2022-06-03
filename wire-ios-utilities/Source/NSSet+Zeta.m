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


#import "NSSet+Zeta.h"



@implementation NSSet (Zeta)

+ (instancetype)zmSetByCompiningSets:(NSSet * const [])sets count:(NSUInteger)cnt;
{
    if (cnt == 0) {
        return [self set];
    } else if (cnt == 1) {
        return sets[0];
    }
    NSMutableSet *result = [NSMutableSet set];
    for (NSUInteger i = 0; i < cnt; ++i) {
        [result unionSet:sets[i]];
    }
    return result;
}

+ (instancetype)zmSetByCompiningSets:(NSSet *)firstSet, ...;
{
    
    NSMutableSet *result = [NSMutableSet setWithSet:firstSet];
    if (firstSet != nil) {
        va_list ap;
        va_start(ap, firstSet);
        while (YES) {
            NSSet *set = va_arg(ap, NSSet *);
            if (set == nil) {
                break;
            }
            [result unionSet:set];
        }
        va_end(ap);
    }
    return result;
}

@end
