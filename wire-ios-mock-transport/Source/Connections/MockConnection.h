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

@protocol ZMTransportData;
@class MockUser;
@class MockConversation;

typedef NS_ENUM(int16_t, ZMTConnectionStatus) {
    ZMTConnectionStatusAccepted,
    ZMTConnectionStatusPending,
    ZMTConnectionStatusBlocked,
    ZMTConnectionStatusIgnored,
    ZMTConnectionStatusSent,
    ZMTConnectionStatusCancelled
};

@interface MockConnection : NSManagedObject

@property (nonatomic, nonnull) NSString *status;
@property (nonatomic, nullable) MockConversation *conversation;
@property (nonatomic, nonnull) MockUser *to;
@property (nonatomic, nonnull) MockUser *from;
@property (nonatomic, nullable) NSDate *lastUpdate;
@property (nonatomic, nullable) NSString *message;

+ (nonnull NSString *)stringFromStatus:(ZMTConnectionStatus)status;
+ (ZMTConnectionStatus)statusFromString:(nonnull NSString *)string;

- (nonnull id<ZMTransportData>)transportData;

- (void)accept;
+ (nonnull NSFetchRequest *)sortedFetchRequest;

+ (nonnull MockConnection *)connectionInMOC:(nonnull NSManagedObjectContext *)moc from:(nonnull MockUser *)from to:(nonnull MockUser *)to message:(nullable NSString *)message;

@end
