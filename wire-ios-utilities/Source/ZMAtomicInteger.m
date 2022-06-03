//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

#import "ZMAtomicInteger.h"
#import <stdatomic.h>

@implementation ZMAtomicInteger
{
    atomic_int _atomicValue;
}

- (instancetype)initWithInteger:(NSInteger)integer;
{
    self = [super init];
    if (self) {
        atomic_store(&_atomicValue, integer);
    }
    return self;
}

- (NSInteger)rawValue
{
    return atomic_load(&_atomicValue);
}

- (NSInteger)increment
{
    atomic_fetch_add(&_atomicValue, 1);
    return atomic_load(&_atomicValue);
}

- (NSInteger)decrement
{
    atomic_fetch_sub(&_atomicValue, 1);
    return atomic_load(&_atomicValue);
}

- (BOOL)setValueWithEqualityCondition:(NSInteger)condition newValue:(NSInteger)newValue;
{
    int expected = (int)condition;
    int desired = (int)newValue;
    return atomic_compare_exchange_strong(&_atomicValue, &expected, desired);
}

@end
