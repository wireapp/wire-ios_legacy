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
#import <CoreData/CoreData.h>

@class MockConversation;
@protocol ZMTransportData;
@class MockUser;


@interface MockEvent : NSManagedObject

@property (nonatomic, nullable) MockUser *from;
@property (nonatomic, nonnull) NSString *identifier;
@property (nonatomic, nullable) NSDate *time;
@property (nonatomic, nonnull) NSString *type;
@property (nonatomic, readonly) ZMUpdateEventType eventType;
@property (nonatomic, nullable) id data;
@property (nonatomic, nullable) NSData* decryptedOTRData;
@property (nonatomic, nullable) MockConversation *conversation;

- (nonnull id<ZMTransportData>)transportData;

+ (nullable NSString *)stringFromType:(ZMUpdateEventType)type;
+ (ZMUpdateEventType)typeFromString:(nonnull NSString *)string;

// Event considered persistent on the backend should receive an identifier
+ (nonnull NSArray *)persistentEvents;

@end
