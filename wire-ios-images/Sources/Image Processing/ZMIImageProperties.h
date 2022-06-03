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


@import CoreGraphics;
@import Foundation;

@interface ZMIImageProperties : NSObject

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly, copy) NSString *mimeType;

+ (instancetype)imagePropertiesWithSize:(CGSize)size length:(NSUInteger)length mimeType:(NSString *)type;

@end
