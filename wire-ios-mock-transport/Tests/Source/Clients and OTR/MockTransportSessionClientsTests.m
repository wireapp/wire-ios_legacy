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


#import "MockTransportSessionTests.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@interface MockTransportSessionClientsTests : MockTransportSessionTests

- (NSMutableDictionary *)payloadtoRegisterClient:(NSUInteger)keysCount;

@end

@implementation MockTransportSessionClientsTests

- (NSMutableDictionary *)payloadtoRegisterClient:(NSUInteger)keysCount password:(NSString *)password
{
    NSMutableDictionary *payload = [NSMutableDictionary new];
    NSString *type = @"permanent";
    NSString *label = @"testClient";
    NSString *time = [NSDate dateWithTimeIntervalSince1970:1234444444].transportString;
    NSMutableArray *prekeysPayload = [NSMutableArray new];
    for (NSUInteger i = 0; i < keysCount; i++) {
        [prekeysPayload addObject:@{@"id": @(i), @"key": [NSString createAlphanumericalString]}];
    }
    NSMutableDictionary *lastPreKeyPayload = [@{@"id": @(0xFFFF), @"key": [NSString createAlphanumericalString]} mutableCopy];
    NSMutableDictionary *sigkeysPayload = [@{@"enckey": [NSString createAlphanumericalString], @"mackey": [NSString createAlphanumericalString]} mutableCopy];
    payload[@"type"] = type;
    payload[@"label"] = label;
    payload[@"lastkey"] = lastPreKeyPayload;
    payload[@"prekeys"] = prekeysPayload;
    payload[@"sigkeys"] = sigkeysPayload;
    payload[@"time"] = time;
    payload[@"latitude"] = @{
                             @"lat" : @(50.32),
                             @"lon" : @(-23.3)
                             };
    payload[@"model"] = @"iPad Air Pro Max C 4 Plus";
    payload[@"address"] = @"127.0.0.10";
    payload[@"class"] = @"tablet";
    if (password) {
        payload[@"password"] = password;
    }
    
    return payload;
}

- (NSMutableDictionary *)payloadtoRegisterClient:(NSUInteger)keysCount
{
    return [self payloadtoRegisterClient:keysCount password:nil];
}

@end


#pragma mark - REST API
@implementation MockTransportSessionClientsTests (REST_API)

- (void)testThatItCanRegisterClient {
    // GIVEN

    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"Cestmonmotdepassesupermagique";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount password:selfUser.password];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);

    NSDictionary *responsePayload = [[response payload] asDictionary];
    NSString *clientId = responsePayload[@"id"];
    XCTAssertNotNil(clientId);
    
    [self.sut.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *clientsRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
        NSArray *clients = [self.sut.managedObjectContext executeFetchRequestOrAssert:clientsRequest];
        XCTAssertEqual(clients.count, 1u);
        MockUserClient *client = [clients firstObjectMatchingWithBlock:^BOOL(MockUserClient *obj) {
            return [obj.identifier isEqualToString:clientId];
        }];
        
        XCTAssertEqualObjects(responsePayload, [client transportData]);
        XCTAssertEqualObjects(client.type, responsePayload[@"type"]);
        XCTAssertEqualObjects(client.label, responsePayload[@"label"]);
        XCTAssertEqualObjects(client.model, responsePayload[@"model"]);
        XCTAssertEqualObjects(client.time.transportString, responsePayload[@"time"]);
        XCTAssertEqualObjects(client.address, responsePayload[@"address"]);
        XCTAssertEqualObjects(client.deviceClass, responsePayload[@"class"]);
        XCTAssertEqualObjects(@(client.locationLatitude), responsePayload[@"location"][@"lat"]);
        XCTAssertEqualObjects(@(client.locationLongitude), responsePayload[@"location"][@"lon"]);
        XCTAssertNotNil(client.identifier);
        
        NSFetchRequest *keysRequest = [NSFetchRequest fetchRequestWithEntityName:@"PreKey"];
        keysRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        NSMutableArray *preKeys = [[self.sut.managedObjectContext executeFetchRequestOrAssert:keysRequest] mutableCopy];

        XCTAssertEqual(preKeys.count, clients.count * (keysCount + 1));
        
        MockPreKey *lastPreKey = preKeys.lastObject;
        [preKeys removeLastObject];
        
        NSMutableSet *intersectPrekeys = [client.prekeys mutableCopy];
        [intersectPrekeys intersectSet:[NSSet setWithArray:preKeys]];
        
        XCTAssertEqualObjects(intersectPrekeys, client.prekeys);
        XCTAssertEqualObjects(client.lastPrekey, lastPreKey);
        
        AssertArraysContainsSameObjects(selfUser.clients.allObjects, clients);
    }];
}

- (void)testThatItCanRegisterSecondClientWithPassword {
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];

    (void)[self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];

    // WHEN
    //uploading second client
    
    NSString *secondLabel = @"anotherClient";
    payload[@"label"] = secondLabel;
    payload[@"password"] = selfUser.password;
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    NSDictionary *responsePayload = [[response payload] asDictionary];
    NSString *clientId = responsePayload[@"id"];
    XCTAssertNotNil(clientId);
    
    [self.sut.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *clientsRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
        NSArray *clients = [self.sut.managedObjectContext executeFetchRequestOrAssert:clientsRequest];
        XCTAssertEqual(clients.count, 2u);
        MockUserClient *client = [[clients filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"label == %@", secondLabel]] firstObject];
        
        XCTAssertEqualObjects(responsePayload, [client transportData]);
        XCTAssertEqualObjects(client.type, responsePayload[@"type"]);
        XCTAssertNotNil(client.identifier);
        
        NSFetchRequest *keysRequest = [NSFetchRequest fetchRequestWithEntityName:@"PreKey"];
        keysRequest.predicate = [NSPredicate predicateWithFormat:@"client == %@ || lastPrekeyOfClient == %@", client, client];
        keysRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
        NSMutableArray *preKeys = [[self.sut.managedObjectContext executeFetchRequestOrAssert:keysRequest] mutableCopy];

        XCTAssertEqual(preKeys.count, keysCount + 1);

        MockPreKey *lastPreKey = preKeys.lastObject;
        [preKeys removeLastObject];
        
        AssertArraysContainsSameObjects(client.prekeys.allObjects, preKeys);
        XCTAssertEqualObjects(client.lastPrekey, lastPreKey);
        
        AssertArraysContainsSameObjects(selfUser.clients.allObjects, clients);
    }];
}

- (void)testThatItCanNotRegisterSecondClientWithoutPassword {
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    
    (void)[self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // WHEN
    //uploading second client
    
    NSString *secondLabel = @"anotherClient";
    payload[@"label"] = secondLabel;
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertNil(response.transportSessionError);
    XCTAssertEqualObjects(response.payloadLabel, @"missing-auth");
}

- (void)testThatItCanNotRegisterSecondClientWithWrongPassword {
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    
    (void)[self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // WHEN
    //uploading second client
    
    NSString *secondLabel = @"anotherClient";
    payload[@"label"] = secondLabel;
    payload[@"password"] = @"wrong pass";
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertNil(response.transportSessionError);
    XCTAssertEqualObjects(response.payloadLabel, @"missing-auth");
}

- (void)testThatItCanNotRegisterTooManyClients {
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    
    (void)[self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // WHEN
    //uploading second client
    
    NSString *secondLabel = @"anotherClient";
    payload[@"label"] = secondLabel;
    payload[@"password"] = selfUser.password;
    
    (void)[self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // uploading third client
    payload[@"label"] = @"third client";
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/clients" method:ZMMethodPOST apiVersion:0];

    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertNil(response.transportSessionError);
    XCTAssertEqualObjects(response.payloadLabel, @"too-many-clients");
}

- (void)testThatItCanNotRegisterWithoutLastKey {
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    [payload removeObjectForKey:@"lastkey"];
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithWrongLastKeyId {
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    payload[@"lastkey"][@"id"] = @(200);
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithoutPreKeys {

    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    [payload removeObjectForKey:@"prekeys"];
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithoutType {

    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    [payload removeObjectForKey:@"type"];
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithWrongType {
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    payload[@"type"] = @"invalid";
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithoutMacKey {

    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    [(NSMutableDictionary *)payload[@"sigkeys"] removeObjectForKey:@"mackey"];
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)testThatItCanNotRegisterWithoutApnsEncriptionKey {
    
    NSUInteger keysCount = 100;
    NSMutableDictionary *payload = [self payloadtoRegisterClient:keysCount];
    [(NSMutableDictionary *)payload[@"sigkeys"] removeObjectForKey:@"enckey"];
    
    [self expectFailureResponseWithStatusCode:400 label:nil forPayload:payload];
}

- (void)expectFailureResponseWithStatusCode:(NSInteger)statusCode label:(NSString *)label forPayload:(NSDictionary *)payload
{
    
    // GIVEN
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = @"monmotdepasseesttropsecurisetasvue";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSMutableDictionary *final = [payload mutableCopy];
    final[@"password"] = selfUser.password;
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:[final copy] path:@"/clients" method:ZMMethodPOST apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, statusCode);
    XCTAssertNil(response.transportSessionError);
    if (label != nil) {
        XCTAssertEqualObjects(response.payloadLabel, label);
    }
}

- (void)testThatItCanGetClients {
    // GIVEN
    
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        client = [session registerClientForUser:selfUser label:@"client" type:@"permanent" deviceClass:@"phone"];
        client.deviceClass = @"desktop";
        client.time = [NSDate dateWithTimeIntervalSince1970:10000];
        client.model = @"iPod Touch";
        client.locationLatitude = 23;
        client.locationLongitude = -10;
        client.address = @"10.0.0.2";
        
        [session registerClientForUser:selfUser label:@"foobar" type:@"temporary" deviceClass:@"desktop"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/clients" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    XCTAssertNotNil(response.payload.asArray);
    XCTAssertEqual([response.payload.asArray count], 2u);
    NSDictionary *clientPayload = [response.payload.asArray firstObjectMatchingWithBlock:^BOOL(NSDictionary *dict) {
        return [dict[@"label"] isEqualToString:@"client"];
    }];
    XCTAssertEqualObjects(clientPayload[@"id"], client.identifier);
    XCTAssertEqualObjects(clientPayload[@"type"], client.type);
    XCTAssertEqualObjects(clientPayload[@"label"], client.label);
    XCTAssertEqualObjects(clientPayload[@"class"], @"desktop");
    XCTAssertEqualObjects(clientPayload[@"time"], [NSDate dateWithTimeIntervalSince1970:10000].transportString);
    XCTAssertEqualObjects(clientPayload[@"model"], @"iPod Touch");
    NSDictionary *expectedLocation = @{@"lat" : @(23), @"lon" : @(-10)};
    XCTAssertEqualObjects(clientPayload[@"location"], expectedLocation);
    XCTAssertEqualObjects(clientPayload[@"address"], @"10.0.0.2");
}

- (void)testThatItCanGetClientsOfAUser {
    
    // GIVEN
    __block MockUser *user1;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        user1 = [session insertUserWithName:@"Foo"];
        [session registerClientForUser:user1 label:@"foobar" type:@"temporary" deviceClass:@"desktop"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/users/%@/clients", user1.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    NSArray *clients = [response.payload asArray];
    XCTAssertEqual(clients.count, 2u);
    NSSet *allClientIds = [NSSet setWithArray:[clients mapWithBlock:^id(id<ZMTransportData> obj) {
        NSDictionary *payload = [obj asDictionary];
        if(payload) {
            return payload[@"id"];
        }
        return @"";
    }]];
    NSSet *expectedClientIds = [user1.clients mapWithBlock:^id(MockUserClient *client) {
        return client.identifier;
    }];
    XCTAssertEqualObjects(allClientIds, expectedClientIds);
}

- (void)testThatItCanGetASpecificClient {
    // GIVEN
    
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        
        [session registerClientForUser:selfUser label:@"foobar" type:@"temporary" deviceClass:@"phone"];
        [session registerClientForUser:selfUser label:@"324211xx" type:@"permanent" deviceClass:@"phone"];
        
        client = [session registerClientForUser:selfUser label:@"client" type:@"permanent" deviceClass:@"phone"];
        client.deviceClass = @"desktop";
        client.time = [NSDate dateWithTimeIntervalSince1970:10000];
        client.model = @"iPod Touch";
        client.locationLatitude = 23;
        client.locationLongitude = -10;
        client.address = @"10.0.0.2";
        
        [session registerClientForUser:selfUser label:@"XXXXX" type:@"permanent" deviceClass:@"phone"];

    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/clients/%@", client.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    NSDictionary *clientPayload = [response.payload asDictionary];
    
    XCTAssertEqualObjects(clientPayload[@"id"], client.identifier);
    XCTAssertEqualObjects(clientPayload[@"type"], client.type);
    XCTAssertEqualObjects(clientPayload[@"label"], client.label);
    XCTAssertEqualObjects(clientPayload[@"class"], @"desktop");
    XCTAssertEqualObjects(clientPayload[@"time"], [NSDate dateWithTimeIntervalSince1970:10000].transportString);
    XCTAssertEqualObjects(clientPayload[@"model"], @"iPod Touch");
    NSDictionary *expectedLocation = @{@"lat" : @(23), @"lon" : @(-10)};
    XCTAssertEqualObjects(clientPayload[@"location"], expectedLocation);
    XCTAssertEqualObjects(clientPayload[@"address"], @"10.0.0.2");
}

- (void)testThatItCanDeleteClients {
    // GIVEN
    
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        client = [session registerClientForUser:selfUser label:@"client" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    NSString *path = [NSString stringWithFormat:@"/clients/%@", client.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodDELETE apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    
    // and when
    ZMTransportResponse *response2 = [self responseForPayload:nil path:@"/clients" method:ZMMethodGET apiVersion:0];
    
    // THEN
    XCTAssertNotNil(response2);
    XCTAssertEqual(response2.HTTPStatus, 200);
    XCTAssertNil(response2.transportSessionError);
    XCTAssertEqual([response.payload.asArray count], 0u);
}

@end


@implementation MockTransportSessionClientsTests (ObjectCreation_API)

- (void)testThatItAddsAClient {
    
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        client = [session registerClientForUser:selfUser label:@"client" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(selfUser.clients.count, 1u);
    XCTAssertTrue([selfUser.clients containsObject:client]);
    
}

- (void)testThatItRemovesAClient {
    
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        client = [selfUser.clients anyObject];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session deleteUserClientWithIdentifier:client.identifier forUser:selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(selfUser.clients.count, 0u);
}

- (void)testThatItSendsANoficationWhenRemovingASelfClient {
 
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        [session registerClientForUser:selfUser label:@"self user" type:@"permanent" deviceClass:@"phone"];
        client = [selfUser.clients anyObject];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    NSUInteger previousEventsCount = self.sut.generatedPushEvents.count;
    NSString *clientId = client.identifier;
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session deleteUserClientWithIdentifier:client.identifier forUser:selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(self.sut.generatedPushEvents.count, previousEventsCount+1u);
    MockPushEvent *lastEvent = self.sut.generatedPushEvents.lastObject;
    
    NSDictionary *expectedPayload = @{
                                      @"client" : @{
                                              @"id" : clientId,
                                            },
                                      @"type" : @"user.client-remove"
                                      };
    XCTAssertEqualObjects(lastEvent.payload, expectedPayload);
}

- (void)testThatItSendsANoficationWhenAddingASelfClient {
    
    // GIVEN
    __block MockUser *selfUser;
    __block MockUserClient *client;
    NSString *clientLabel = @"client label";
    NSString *clientType = @"permanent";
    NSString *deviceClass = @"phone";
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        client = [session registerClientForUser:selfUser label:clientLabel type:clientType  deviceClass:deviceClass];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.sut.generatedPushEvents.count, 1u);
    MockPushEvent *lastEvent = self.sut.generatedPushEvents.lastObject;
    
    NSDictionary *expectedPayload = @{
                                      @"client" : @{
                                              @"label" : clientLabel,
                                              @"location" : @{
                                                      @"lat" : @(0),
                                                      @"lon" : @(0)
                                                      },
                                              @"time": client.time.transportString,
                                              @"id" : client.identifier,
                                              @"type" : clientType,
                                              @"class" : deviceClass
                                      },
                                      @"type" : @"user.client-add"
    };
    XCTAssertEqualObjects(lastEvent.payload, expectedPayload);
}

- (void)testThatItDoesNotSendsANoficationWhenAddingAClientOfAnotherUser {
    // GIVEN
    __block MockUser *otherUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        otherUser = [session insertUserWithName:@"Foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session registerClientForUser:otherUser label:@"client" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.sut.generatedPushEvents.count, 0u);
}

- (void)testThatItDoesNotSendsANoficationWhenRemovingAClientOfAnotherUser {
    // GIVEN
    __block MockUser *otherUser;
    __block MockUserClient *client;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        otherUser = [session insertUserWithName:@"Foo"];
        client = [session registerClientForUser:otherUser label:@"client" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        [session deleteUserClientWithIdentifier:client.identifier forUser:otherUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertEqual(self.sut.generatedPushEvents.count, 0u);
}

- (void)testThatEncryptEncryptDataBetweenTwoClients;
{
    __block MockUserClient *selfClient;
    __block MockUserClient *destClient;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Brigite Sorço"];
        selfClient = [session registerClientForUser:selfUser label:@"moi" type:@"permanent" deviceClass:@"phone"];
        destClient = [session registerClientForUser:selfUser label:@"autre" type:@"permanent" deviceClass:@"phone"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSData *clearData = [@"Please, encrypt me!" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [MockUserClient encryptedWithData:clearData from:destClient to:selfClient];
    
    XCTAssertNotNil(encryptedData);
    XCTAssertNotEqualObjects(clearData, encryptedData);
}

@end
