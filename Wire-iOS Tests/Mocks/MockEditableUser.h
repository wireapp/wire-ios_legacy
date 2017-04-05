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
@import WireDataModel;

@interface MockEditableUser : NSObject <ZMEditableUser>

@property (nonatomic, copy) NSString *name;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic) NSData *originalProfileImageData;
@property (nonatomic) NSUInteger deleteProfileImageCallCount;

- (void)deleteProfileImage;

#pragma mark - Mock

+ (instancetype)mockUser;

- (instancetype)initWithName:(NSString *)name
                 accentColor:(ZMAccentColor)color
                       email:(NSString *)email
                 phoneNumber:(NSString *)phoneNumber
                   imageData:(NSData *)data;

@end
