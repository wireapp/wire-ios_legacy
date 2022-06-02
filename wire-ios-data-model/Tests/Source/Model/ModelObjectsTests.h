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


@import WireDataModel;
@import WireTesting;
#import <CoreData/CoreData.h>
#import <WireTransport/WireTransport.h>

#import "ZMConversation+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMBaseManagedObjectTest.h"



@interface ModelObjectsTests : ZMBaseManagedObjectTest

@property (nonatomic) ZMUser *selfUser;
@property (nonatomic) NSManagedObjectModel *model;

- (void)checkAttributeForClass:(Class)aClass key:(NSString *)key value:(id)value;

- (void)withAssertionsDisabled:(void (^)(void))block;

@end
