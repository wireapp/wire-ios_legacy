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
#import "ZMUser.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The result of a property normalization operation.
 */

@interface ZMPropertyNormalizationResult<Value> : NSObject

/// Whether the property is valid.
@property (nonatomic, readonly, getter=isValid) BOOL valid;

/// The value that was normalized during the operation.
@property (nonatomic, readonly, nullable) Value normalizedValue;

/// The error that reprsents the reason why the property is not valid.
@property (nonatomic, readonly, nullable) NSError* validationError;

- (instancetype)initWithResult:(BOOL)valid normalizedValue:(Value)normalizedValue validationError:(NSError * _Nullable )validationError;

@end

NS_ASSUME_NONNULL_END
