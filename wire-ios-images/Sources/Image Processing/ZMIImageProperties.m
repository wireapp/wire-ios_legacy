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


#import "ZMIImageProperties.h"

@interface ZMIImageProperties ()

@property (nonatomic) CGSize size;
@property (nonatomic) NSUInteger length;
@property (nonatomic, copy) NSString *mimeType;

@end

@implementation ZMIImageProperties

+ (instancetype)imagePropertiesWithSize:(CGSize)size length:(NSUInteger)length mimeType:(NSString *)type
{
    ZMIImageProperties *properties = [[ZMIImageProperties alloc] init];
    properties.length = length;
    properties.size = size;
    properties.mimeType = type;
    return properties;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{ length: %lu, type: %@, size:(%f , %f)}", (unsigned long)self.length, self.mimeType, self.size.width, self.size.height];
}

@end
