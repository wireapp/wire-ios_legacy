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
@import CoreData;

/**
 This class helps creating a basic NSManagedObjectContext with few entities, or let you reuse an existing PersistantStoreCoordiator. This get you started for NSManagedObjectContext tests.
 */
@interface ZMMockManagedObjectContextFactory : NSObject

/**
 Creates a mock NSManagedObjectContext from scratch, creating as well an In Memory NSPersistantStoreCoordinator. The concurency type is set to the main queue.
 */
+ (NSManagedObjectContext *)testManagedObjectContext;

/**
 Creates a mock NSManagedObjectContext from scratch with a specific concurency type, creating as well an In Memory NSPersistantStoreCoordinator.
 @param concurencyType The ManagedObjectContext concurency type
 */
+ (NSManagedObjectContext *)testManagedObjectContextWithConcurencyType:(NSManagedObjectContextConcurrencyType)concurencyType;

/**
 Creates a NSManagedObjectContext based on the given NSPersistantStoreCoordinator. The concurency type is set to main queue.
 @param psc The PersistantStoreCoordinator used by the ManagedObjectContext.
 */
+ (NSManagedObjectContext *)alternativeManagedObjectContextForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc;

/**
 Creates a NSManagedObjectContext based on the given NSPersistantStoreCoordinator with a given concurency type.
 @param psc The PersistantStoreCoordinator used by the ManagedObjectContext.
 @param concurencyType The ManagedObjectContext concurency type
 */
+ (NSManagedObjectContext *)alternativeManagedObjectContextForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc concurencyType:(NSManagedObjectContextConcurrencyType)concurencyType;

@end
