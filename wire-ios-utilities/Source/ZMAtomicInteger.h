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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An integer whose value is accessed and updated dynamically by the system.
 */

@interface ZMAtomicInteger : NSObject

/// The raw integer value managed by the system.
@property (nonatomic, readonly) NSInteger rawValue;

- (instancetype)initWithInteger:(NSInteger)integer;

/// Increments the integer value and returns the updated value.
- (NSInteger)increment;

/// Decrements the integer value and returns the updated value.
- (NSInteger)decrement;

/**
 * Checks if the current value is equal to the expected value. If the expected value is equal
 * to the current value, set the current value to the new value.
 * @param condition The condition to evaluate before updating the value.
 * @param newValue The value to set to the integer if the condition evaluated to `YES`.
 * @return Whether the condition evaluated to `YES`.
 */

- (BOOL)setValueWithEqualityCondition:(NSInteger)condition newValue:(NSInteger)newValue;

@end

NS_ASSUME_NONNULL_END
