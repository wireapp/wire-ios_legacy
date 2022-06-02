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


#import "ModelObjectsTests.h"

#import "ZMManagedObject+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMMessage+Internal.h"
#import "NSManagedObjectContext+tests.h"



@interface PassiveAssertionHandler : NSAssertionHandler

@end

@implementation PassiveAssertionHandler


- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...
{
    NOT_USED(selector); NOT_USED(object); NOT_USED(fileName); NOT_USED(line); NOT_USED(format);
    // do nothing
}

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...
{
    NOT_USED(functionName); NOT_USED(fileName); NOT_USED(line); NOT_USED(format);
    // do nothing
}

@end



@implementation ModelObjectsTests

- (void)setUp
{
    [super setUp];
    [self loadManagedObjectModel];
    [self setupSelfConversation];
    WaitForAllGroupsToBeEmpty(0.2);
}

- (void)tearDown
{
    _model = nil;
    self.selfUser = nil;
    [super tearDown];
}

- (void)setupSelfConversation
{
    NSUUID *selfUserID = [NSUUID createUUID];
    self.selfUser = [ZMUser selfUserInContext:self.uiMOC];
    self.selfUser.remoteIdentifier = selfUserID;
    ZMConversation *selfConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    selfConversation.remoteIdentifier = selfUserID;
    selfConversation.conversationType = ZMConversationTypeSelf;
    [selfConversation addParticipantAndUpdateConversationStateWithUser:self.selfUser role:nil];
    [self.uiMOC saveOrRollback];
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC refreshObject:[ZMUser selfUserInContext:self.syncMOC] mergeChanges:NO];
    }];
    
}

- (void)loadManagedObjectModel;
{
    NSBundle *modelBundle = [NSBundle bundleForClass:[ZMManagedObject class]];
    _model = [NSManagedObjectModel mergedModelFromBundles:@[modelBundle]];
    XCTAssertNotNil(_model, @"Unable to load zmessaging model.");
}

- (void)checkAttributeForClass:(Class)aClass key:(NSString *)key value:(id)value;
{
    ZMManagedObject *mo1 = [aClass insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertNotNil(mo1);
    
    [mo1 setValue:value forKey:key];
    XCTAssertEqualObjects([mo1 valueForKey:key], value);

    NSError *error;
    XCTAssertTrue([self.uiMOC save:&error], @"Save failed: %@", error);
    
    __block NSManagedObject *mo2 = nil;
    __block id valueFromMo2 = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        NSError *errorOnBlock;

        mo2 = (id) [self.syncMOC existingObjectWithID:mo1.objectID error:&errorOnBlock];
        XCTAssertNotNil(mo2, @"Failed to load into other context: %@", errorOnBlock);
        valueFromMo2 = [mo2 valueForKey:key];
    }];
    
    XCTAssertEqualObjects(valueFromMo2, [mo1 valueForKey:key]);
}


- (void)withAssertionsDisabled:(void(^)(void))block
{
    NSAssertionHandler *oldHandler =  [[[NSThread currentThread] threadDictionary] valueForKey:NSAssertionHandlerKey];
    [[[NSThread currentThread] threadDictionary] setValue:[[PassiveAssertionHandler alloc] init] forKey:NSAssertionHandlerKey];

    block();

    [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];
}


@end
