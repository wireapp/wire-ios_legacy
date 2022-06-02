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


#import "MockAsset.h"


@implementation MockAsset

@dynamic identifier;
@dynamic data;
@dynamic contentType;
@dynamic conversation;
@dynamic token;
@dynamic domain;

+ (MockAsset *)assetInContext:(NSManagedObjectContext *)managedObjectContext forID:(NSString *)identifier
{
    return [MockAsset assetInContext:managedObjectContext forID:identifier domain:NULL];
}

+ (MockAsset *)assetInContext:(NSManagedObjectContext *)managedObjectContext forID:(NSString *)identifier domain:(NSString *)domain
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Asset"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND domain == %@", identifier, domain];

    NSArray *result = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    NSAssert(result != nil, @"Something wrong in fetching asset");
    NSAssert(result.count < 2, @"Too many assets with same id");

    return result.firstObject;
}

+ (instancetype)insertIntoManagedObjectContext:(NSManagedObjectContext *)moc;
{
    MockAsset *asset = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Asset" inManagedObjectContext:moc];
    return asset;
}

@end
