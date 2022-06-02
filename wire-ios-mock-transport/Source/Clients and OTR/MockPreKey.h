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


@import CoreData;
@import WireCryptobox;

@class MockUserClient;

@interface MockPreKey : NSManagedObject

@property (nonatomic, nonnull) MockUserClient *client;
@property (nonatomic, nullable) MockUserClient *lastPrekeyOfClient;

@property (nonatomic) NSInteger identifier;
@property (nonatomic, nonnull) NSString *value;

+ (nullable instancetype)insertNewKeyWithPayload:(nonnull NSDictionary *)payload context:(nonnull NSManagedObjectContext *)context;;

+ (nonnull NSSet<MockPreKey *> *)insertNewKeysWithPayload:(nonnull NSArray *)payload context:(nonnull NSManagedObjectContext *)context;;

+ (nonnull NSArray <MockPreKey *> *)insertMockPrekeysFromPrekeys:(nonnull NSArray <NSString *> *)prekeys forClient:(nonnull MockUserClient *)client inManagedObjectContext:(nonnull NSManagedObjectContext *)moc;
+ (nonnull MockPreKey *)insertNewKeyWithPrekey:(nonnull NSString *)prekey forClient:(nonnull MockUserClient *)client inManagedObjectContext:(nonnull NSManagedObjectContext *)moc;

@end
