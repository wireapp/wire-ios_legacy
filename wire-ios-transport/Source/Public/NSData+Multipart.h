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

NS_ASSUME_NONNULL_BEGIN

@interface ZMMultipartBodyItem : NSObject

@property (nonatomic, readonly, copy) NSData *data;
@property (nonatomic, readonly, copy, nullable) NSString *contentType;
@property (nonatomic, readonly, copy, nullable) NSDictionary *headers;

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType headers:(nullable NSDictionary *)headers;
- (instancetype)initWithMultipartData:(NSData *)data;

- (BOOL)isEqualToItem:(ZMMultipartBodyItem *)object;

@end

@interface NSData (Multipart)

+ (NSData *)multipartDataWithItems:(NSArray *)items boundary:(NSString *)boundary;

- (NSArray *)multipartDataItemsSeparatedWithBoundary:(NSString *)boundary;

- (NSArray *)componentsSeparatedByData:(NSData *)boundary;
- (NSArray *)lines;


@end

NS_ASSUME_NONNULL_END
