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

@import WireUtilities;

#import "ZMUserTests.h"
#import "ModelObjectsTests.h"

#import "ZMUser+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConnection+Internal.h"
#import "WireDataModelTests-Swift.h"


static NSString * const InvitationToConnectBaseURL = @"https://www.wire.com/c/";

static NSString *const ValidPhoneNumber = @"+491234567890";
static NSString *const ShortPhoneNumber = @"+491";
static NSString *const LongPhoneNumber = @"+4912345678901234567890";
static NSString *const ValidPassword = @"pA$$W0Rd";
static NSString *const ShortPassword = @"pa";
static NSString *const LongPassword =
@"ppppppppppppaaaaaaaaaaassssssssswwwwwwwwwwoooooooooooorrrrrrrrrddddddddddddddd"
"ppppppppppppaaaaaaaaaaassssssssswwwwwwwwwwoooooooooooorrrrrrrrrddddddddddddddd"
"ppppppppppppaaaaaaaaaaassssssssswwwwwwwwwwoooooooooooorrrrrrrrrddddddddddddddd"
"ppppppppppppaaaaaaaaaaassssssssswwwwwwwwwwoooooooooooorrrrrrrrrddddddddddddddd";
static NSString *const ValidPhoneCode = @"123456";
static NSString *const ShortPhoneCode = @"1";
static NSString *const LongPhoneCode = @"123456789012345678901234567890";
static NSString *const ValidEmail = @"foo77@example.com";
static NSString *const ManagedByWire = @"wire";
static NSString *const ManagedByScim = @"scim";


static NSString *const MediumRemoteIdentifierDataKey = @"mediumRemoteIdentifier_data";
static NSString *const SmallProfileRemoteIdentifierDataKey = @"smallProfileRemoteIdentifier_data";
static NSString *const ImageMediumDataKey = @"imageMediumData";
static NSString *const ImageSmallProfileDataKey = @"imageSmallProfileData";

@interface ZMUserTests()

@property (nonatomic) NSArray *validPhoneNumbers;
@property (nonatomic) NSArray *shortPhoneNumbers;
@property (nonatomic) NSArray *longPhoneNumbers;

@end


@implementation ZMUserTests

-(void)setUp
{
    [super setUp];
    self.validPhoneNumbers = @[@"+491621312533", @"+4901756698655", @"+49 152 22824948", @"+49 157 71898972", @"+49 176 35791100", @"+49 1721496444", @"+79263387698", @"+79160546401", @"+7(927)674-59-42", @"+71231234567", @"+491234567890123456", @"+49123456789012345678901", @"+49123456"];
    self.shortPhoneNumbers = @[@"+", @"4", @"+4", @"+49", @"+491", @"+4912", @"+49123", @"+491234", @"+491235"];
    self.longPhoneNumbers = @[@"+491234567890123456789015", @"+4912345678901234567890156"];
    
    UserImageLocalCache *userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.zm_userImageCache = userImageCache;
    }];
    
    self.uiMOC.zm_userImageCache = userImageCache;
}

- (void)tearDown
{
    self.validPhoneNumbers = nil;
    self.shortPhoneNumbers = nil;
    self.longPhoneNumbers = nil;
    [super tearDown];
}

- (void)testThatItHasLocallyModifiedDataFields
{
    XCTAssertTrue([ZMUser isTrackingLocalModifications]);
    NSEntityDescription *entity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMUser.entityName];
    XCTAssertNotNil(entity.attributesByName[@"modifiedKeys"]);
}

- (void)testThatWeCanSetAttributesOnUser
{
    [self checkUserAttributeForKey:@"accentColorValue" value:@(ZMAccentColorVividRed)];
    [self checkUserAttributeForKey:@"emailAddress" value:@"foo@example.com"];
    [self checkUserAttributeForKey:@"name" value:@"Foo Bar"];
    [self checkUserAttributeForKey:@"handle" value:@"foo_bar"];
    [self checkUserAttributeForKey:@"managedBy" value:ManagedByWire];
    [self checkUserAttributeForKey:@"phoneNumber" value:@"+123456789"];
    [self checkUserAttributeForKey:@"remoteIdentifier" value:[NSUUID createUUID]];
    [self checkUserAttributeForKey:@"richProfile" value:@[
                                                                [[UserRichProfileField alloc] initWithType:@"Title" value:@"Software Engineer"],
                                                                [[UserRichProfileField alloc] initWithType:@"Department" value:@"iOS Team"]
                                                               ]];
}

- (NSMutableDictionary *)samplePayloadForUserID:(NSUUID *)userID
{
    return [@{
              @"name" : @"Manuel Rodriguez",
              @"id" : userID.transportString,
              @"handle" : @"el_manu",
              @"email" : @"mannie@example.com",
              @"phone" : @"000-000-45789",
              @"accent_id" : @3,
              @"picture" : @[],
              @"managed_by" : ManagedByWire
              } mutableCopy];
}

- (void)checkUserAttributeForKey:(NSString *)key value:(id)value;
{
    [self checkAttributeForClass:[ZMUser class] key:key value:value];
}

- (void)testThatItReturnsAnExistingUserByUUID
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSUUID *uuid = [NSUUID createUUID];
    user.remoteIdentifier = uuid;

    // when
    ZMUser *found = [ZMUser fetchWith:uuid in:self.uiMOC];

    // then
    XCTAssertEqualObjects(found.remoteIdentifier, uuid);
    XCTAssertEqualObjects(found.objectID, user.objectID);
}

- (void)testThatItDoesNotReturnANonExistingUserByUUID
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *secondUUID = [NSUUID createUUID];

    user.remoteIdentifier = uuid;

    // when
    ZMUser *found = [ZMUser fetchWith:secondUUID in:self.uiMOC];

    // then
    XCTAssertNil(found);
}

- (void)testThatItCreatesAUserForNonExistingUUID
{
    // given
    NSUUID *uuid = [NSUUID createUUID];

    [self.syncMOC performBlockAndWait:^{
        // when
        ZMUser *created = [ZMUser fetchOrCreateWith:uuid domain:nil in:self.syncMOC];
        
        // then
        XCTAssertNotNil(created);
        XCTAssertEqualObjects(uuid, created.remoteIdentifier);
    }];
}

- (void)testThatItReturnsAnExistingUserByPhone
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *phoneNumber = @"+123456789";
    user.phoneNumber = phoneNumber;
    
    // when
    ZMUser *found = [ZMUser userWithPhoneNumber:phoneNumber inContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(found.phoneNumber, phoneNumber);
    XCTAssertEqualObjects(found.objectID, user.objectID);
}

- (void)testThatItDoesNotReturnANonExistingUserByPhone
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *phoneNumber = @"+123456789";
    user.phoneNumber = phoneNumber;
    
    NSString *otherPhoneNumber = @"+987654321";
    
    // when
    ZMUser *found = [ZMUser userWithPhoneNumber:otherPhoneNumber inContext:self.uiMOC];
    
    // then
    XCTAssertNil(found);
}

- (void)testThatItReturnsAnExistingUserByEmail
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *emailAddress = @"test@test.com";
    user.emailAddress = emailAddress;
    
    // when
    ZMUser *found = [ZMUser userWithEmailAddress:emailAddress inContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(found.emailAddress, emailAddress);
    XCTAssertEqualObjects(found.objectID, user.objectID);
}

- (void)testThatItDoesNotReturnANonExistingUserByEmail
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *emailAddress = @"east@test.com";
    user.emailAddress = emailAddress;
    
    NSString *otherEmailAddress = @"west@test.com";
    
    // when
    ZMUser *found = [ZMUser userWithEmailAddress:otherEmailAddress inContext:self.uiMOC];
    
    // then
    XCTAssertNil(found);
}

- (void)testThatItUpdatesServiceDataOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString * mockServiceIdentifier = @"mock serviceIdentifier";
    NSString * mockProviderIdentifier = @"mock providerIdentifier";

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"service"][@"id"] = mockServiceIdentifier;
    payload[@"service"][@"provider"] = mockProviderIdentifier;

    // when
    [user updateWithTransportData:payload authoritative:NO];

    // then
    XCTAssertEqualObjects(user.serviceIdentifier, payload[@"service"][@"id"]);
    XCTAssertEqualObjects(user.providerIdentifier, payload[@"service"][@"provider"]);
}

- (void)testThatItUpdatesSSODataOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"sso_id"] = @{@"tenant": @"some-xml", @"subject": @"hekki"};
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssert(user.usesCompanyLogin);
}

- (void)testThatItDoesntUpdateSSODataOnAnExistingUser_WhenSubjectIsEmpty
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"sso_id"] = @{@"tenant": @"some-xml", @"subject": @""};

    // when
    [user updateWithTransportData:payload authoritative:NO];

    // then
    XCTAssertFalse(user.usesCompanyLogin);
}

- (void)testThatItUpdatesSSODataOnAnExistingUserWhenRefetchingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"sso_id"] = @{@"tenant": @"some-xml", @"subject": @"hekki"};
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    [user updateWithTransportData:[self samplePayloadForUserID:uuid] authoritative:NO];

    // then
    XCTAssert(user.usesCompanyLogin);
}

- (void)testThatItUpdatesSSODataOnAnExistingUser_NoSSOData
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertFalse(user.usesCompanyLogin);
}

- (void)testThatItUpdatesTeamIdentifierOnExistingUser
{
    // given
    NSUUID *uuid = NSUUID.createUUID;
    NSUUID *teamId = NSUUID.createUUID;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = teamId.transportString;
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqualObjects(user.teamIdentifier.transportString, teamId.transportString);
    XCTAssert(user.hasTeam);
}

- (void)testThatItUpdatesTeamIdentifierOnExistingUser_NilValue
{
    // given
    NSUUID *uuid = NSUUID.createUUID;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertNil(user.teamIdentifier);
    XCTAssertFalse(user.hasTeam);
}

- (void)testThatItCreatesMembershipIfUserBelongsToSelfUserTeamOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *teamId = NSUUID.createUUID;
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = teamId;
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = teamId.transportString;
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];
    
    // then
    XCTAssertNotNil(user.membership);
    XCTAssertEqualObjects(user.membership.team, team);
}

- (void)testThatItDoesNotCreateMembershipIfUserIsDeleted
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *teamId = NSUUID.createUUID;
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = teamId;
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = teamId.transportString;
    payload[@"deleted"] = @YES;
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];
    
    // then
    XCTAssertNil(user.membership);
}

- (void)testThatItDoesNotUpdateNameIfUserIsDeleted
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *teamId = NSUUID.createUUID;
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = teamId;
    user.remoteIdentifier = uuid;
    user.name = @"bob";

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = teamId.transportString;
    payload[@"deleted"] = @YES;
    payload[@"name"] = @"default";

    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];

    // then
    XCTAssertEqual(user.name, @"bob");
}

- (void)testThatItDoesNotCreateMembershipIfUserBelongsExternalTeamOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *teamId = NSUUID.createUUID;
    NSUUID *externalTeamId = NSUUID.createUUID;
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = teamId;
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = externalTeamId.transportString;
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];
    
    // then
    XCTAssertNil(user.membership);
}

- (void)testThatItDeletesMembershipIfUserBelongsToSelfUserTeamOnAnExistingUserWhoIsMarkedAsDeleted
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    NSUUID *teamId = NSUUID.createUUID;
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = teamId;
    user.remoteIdentifier = uuid;

    Member *membership = [Member insertNewObjectInManagedObjectContext:self.uiMOC];
    membership.user = user;
    membership.team = team;

    XCTAssertNotNil(user.membership);
    XCTAssertEqualObjects(user.membership.team, team);

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"team"] = teamId.transportString;
    payload[@"deleted"] = [NSNumber numberWithBool:YES];

    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];

    // then
    XCTAssertTrue(user.isAccountDeleted);
    XCTAssertTrue(user.membership.isDeleted);
}

- (void)testThatItUpdatesBasicDataOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];

    // then
    XCTAssertEqualObjects(user.name, payload[@"name"]);
    XCTAssertEqualObjects(user.emailAddress, payload[@"email"]);
    XCTAssertEqualObjects(user.phoneNumber, payload[@"phone"]);
    XCTAssertEqualObjects(user.handle, payload[@"handle"]);
    XCTAssertEqual([self managedByString:user], payload[@"managed_by"]);
    XCTAssertNil(user.expiresAt);
    XCTAssertEqual(user.accentColorValue, ZMAccentColorBrightYellow);
}

- (void)testThatItUpdatesAccountDeletionStatusOnAnExistingUser
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    XCTAssertFalse(user.isAccountDeleted);
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"deleted"] = @YES;
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertTrue(user.isAccountDeleted);
}

- (void)testThatItUpdatesExpirationAnExistingUser
{
    // given
    NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:60 * 10];
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    payload[@"expires_at"] = [expireDate transportString];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqualObjects(user.expiresAt.transportString, expireDate.transportString);
}

- (void)testThatItUpdatesBasicDataOnAnExistingUserWithoutAccentID
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"accent_id"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqualObjects(user.name, payload[@"name"]);
    XCTAssertEqualObjects(user.emailAddress, payload[@"email"]);
    XCTAssertEqualObjects(user.phoneNumber, payload[@"phone"]);
    XCTAssertEqualObjects(user.handle, payload[@"handle"]);
    XCTAssertEqualObjects([self managedByString:user], payload[@"managed_by"]);
}


- (void)testThatItUpdatesBasicDataOnAnExistingUserWithoutPicture
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"picture"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqualObjects(user.name, payload[@"name"]);
    XCTAssertEqualObjects(user.emailAddress, payload[@"email"]);
    XCTAssertEqualObjects(user.phoneNumber, payload[@"phone"]);
    XCTAssertEqualObjects(user.handle, payload[@"handle"]);
    XCTAssertEqualObjects([self managedByString:user], payload[@"managed_by"]);
}


- (void)testThatItLimitsAccentColorsToValidRangeForUdpateData_TooLarge;
{
    // given
    NSUUID *remoteID = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = remoteID;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:remoteID];
    payload[@"accent_id"] = @(ZMAccentColorMax + 1);
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertGreaterThan(user.accentColorValue, ZMAccentColorUndefined);
    XCTAssertLessThanOrEqual(user.accentColorValue, ZMAccentColorMax);
}

- (void)testThatItLimitsAccentColorsToValidRangeForUdpateData_Undefined;
{
    // given
    NSUUID *remoteID = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = remoteID;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:remoteID];
    payload[@"accent_id"] = @(ZMAccentColorUndefined);
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertGreaterThan(user.accentColorValue, ZMAccentColorUndefined);
    XCTAssertLessThanOrEqual(user.accentColorValue, ZMAccentColorMax);
}

- (void)testThatItDoesPersistCompleteImageDataToCache
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.completeProfileAssetIdentifier = @"123";
    NSData *imageData = [self verySmallJPEGData];
    [user setImageData:imageData size:ProfileImageSizeComplete];
    XCTAssertEqualObjects(user.imageMediumData, imageData);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];
    
    //when
    NSData* extractedData = [self.uiMOC.zm_userImageCache userImage:user size:ProfileImageSizeComplete];
    
    //then
    XCTAssertEqualObjects(imageData, extractedData);
}

- (void)testThatItDoesPersistPreviewImageDataToCache
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.previewProfileAssetIdentifier = @"123";
    NSData *imageData = [self verySmallJPEGData];
    [user setImageData:imageData size:ProfileImageSizePreview];
    XCTAssertEqualObjects(user.imageSmallProfileData, imageData);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];
    
    //when
    NSData* extractedData = [self.uiMOC.zm_userImageCache userImage:user size:ProfileImageSizePreview];
    
    //then
    XCTAssertEqualObjects(imageData, extractedData);
}

- (void)testProfileImageCanBeFetchedAsynchrounously
{
    // given
    NSData *imageData = [self verySmallJPEGData];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = [NSUUID createUUID];
    user.completeProfileAssetIdentifier = @"123";
    user.previewProfileAssetIdentifier = @"321";
    [user setImageData:imageData size:ProfileImageSizeComplete];
    [user setImageData:imageData size:ProfileImageSizePreview];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC saveOrRollback];
    }];
    
    // expect
    XCTestExpectation *previewDataArrived = [self expectationWithDescription:@"preview image data arrived"];
    XCTestExpectation *completeDataArrived = [self expectationWithDescription:@"complete image data arrived"];
    
    // when
    [user imageDataFor:ProfileImageSizePreview queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) completion:^(NSData *imageDataResult) {
        XCTAssert([imageDataResult isEqualToData:imageData]);
        [previewDataArrived fulfill];
    }];
    
    [user imageDataFor:ProfileImageSizeComplete queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) completion:^(NSData *imageDataResult) {
        XCTAssert([imageDataResult isEqualToData:imageData]);
        [completeDataArrived fulfill];
    }];
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItHandlesEmptyOptionalData
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"phone"];
    [payload removeObjectForKey:@"accent_id"];

    // when
    [self performIgnoringZMLogError:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];
    
    // then
    XCTAssertNil(user.phoneNumber);
}


- (void)testThatItSetsNameToNilIfItIsMissing
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.name =  @"Mario";
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"name"];

    // when
    [self performIgnoringZMLogError:^{
        [user updateWithTransportData:payload authoritative:YES];
    }];
    // then
    XCTAssertNil(user.name);
}

- (void)testThatTheEmailIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    user.emailAddress = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(user.emailAddress, originalValue);
}

- (void)testThatItSetsEmailToNilIfItIsNull
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.emailAddress =  @"gino@pino.it";
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload setObject:[NSNull null] forKey:@"email"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertNil(user.emailAddress);
}

- (void)testThatItSetsEmailToNilIfItIsMissing
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.emailAddress =  @"gino@pino.it";

    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"email"];
    
    // when
    [user updateWithTransportData:payload authoritative:YES];

    // then
    XCTAssertNil(user.emailAddress);
}

- (void)testThatItSetsManagedByAsWire
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload setObject:ManagedByWire forKey:@"managed_by"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqual([self managedByString:user], ManagedByWire);
}

- (void)testThatNilManagedByIsConsideredAsManagedByWire
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"managed_by"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertTrue(user.managedByWire);
}

- (void)testThatItSetsManagedByAsScim
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload setObject:ManagedByScim forKey:@"managed_by"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertEqual([self managedByString:user], ManagedByScim);
}

- (void)testThatItSetsPhoneToNilIfItIsNull
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.phoneNumber =  @"555-fake-number";
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload setObject:[NSNull null] forKey:@"phone"];
    
    // when
    [user updateWithTransportData:payload authoritative:NO];
    
    // then
    XCTAssertNil(user.phoneNumber);
}

- (void)testThatItSetsPhoneToNilIfItIsMissing
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.phoneNumber =  @"555-fake-number";
    
    NSMutableDictionary *payload = [self samplePayloadForUserID:uuid];
    [payload removeObjectForKey:@"phone"];
    
    // when
    [user updateWithTransportData:payload authoritative:YES];
    
    // then
    XCTAssertNil(user.phoneNumber);
}

- (void)testThatThePhoneNumberIsCopied
{
    // given
    NSString *originalValue = @"+1-555-324545";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    user.phoneNumber = mutableValue;
    [mutableValue appendString:@"8"];
    
    // then
    XCTAssertEqualObjects(user.phoneNumber, originalValue);
}

- (void)testThatItAssignsRemoteIdentifierIfTheUserDoesNotHaveOne
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSDictionary *payload = [self samplePayloadForUserID:[NSUUID createUUID]];
    
    // when
    [user updateWithTransportData:payload authoritative:YES];

    // then
    XCTAssertEqualObjects(user.remoteIdentifier, [payload[@"id"] UUID]);
}

- (void)testThatItAssignsQualifiedIDIfTheUserDoesNotHaveOne
{
    // given
    NSUUID *remoteIdentifier = [NSUUID createUUID];
    NSString *domain = @"example.com";
    
    NSDictionary *qualifedIDPayload = @{
        @"id": remoteIdentifier.transportString,
        @"domain": domain
    };
    
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSMutableDictionary *payload = [self samplePayloadForUserID:[NSUUID createUUID]];
    payload[@"qualified_id"] = qualifedIDPayload; 
    
    // when
    [user updateWithTransportData:payload authoritative:YES];

    // then
    XCTAssertEqualObjects(user.remoteIdentifier, [qualifedIDPayload[@"id"] UUID]);
    XCTAssertEqualObjects(user.domain, qualifedIDPayload[@"domain"]);
}



- (void)testThatItIsMarkedAsUpdatedFromBackendWhenUpdatingWithAuthoritativeData
{

    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;

    NSDictionary *userData = [self samplePayloadForUserID:uuid];

    // when
    [user updateWithTransportData:userData authoritative:YES];

    // then
    XCTAssertFalse(user.needsToBeUpdatedFromBackend);
}


- (void)testThatIsNotMarkedAsUpdatedFromBackendWhenUpdatingWithNonAuthoritativeData
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    XCTAssertTrue(user.needsToBeUpdatedFromBackend);
    
    NSDictionary *userData = [self samplePayloadForUserID:uuid];

    // when
    [user updateWithTransportData:userData authoritative:NO];

    // then
    XCTAssertTrue(user.needsToBeUpdatedFromBackend);
}

- (void)testThatWhenNonAuthoritativeIsMissingDataFieldsThoseAreNotSetToNil
{
    
    //given
    NSString *name = @"Jean of Arc";
    NSString *email = @"jj@arc.example.com";
    NSString *phone = @"+33 11111111111";
    NSString *handle = @"st_jean";
    
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    user.emailAddress =  email;
    user.name = name;
    user.handle = handle;
    user.phoneNumber = phone;
    
    NSDictionary *payload = @{
                              @"id": [uuid transportString]
                              };
    
    // when
    [self performIgnoringZMLogError:^{
        [user updateWithTransportData:payload authoritative:NO];
    }];
    
    // then
    XCTAssertEqualObjects(name, user.name);
    XCTAssertEqualObjects(email, user.emailAddress);
    XCTAssertEqualObjects(phone, user.phoneNumber);
    XCTAssertEqualObjects(handle, user.handle);
}

- (void)testThatOnInvalidJsonDataTheUserIsMarkedAsComplete
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    XCTAssertTrue(user.needsToBeUpdatedFromBackend);

    NSDictionary *payload = @{@"id":[uuid transportString]};
    
    // when
    [self performIgnoringZMLogError:^{
        [user updateWithTransportData:payload authoritative:YES];
    }];
    
    // then
    XCTAssertFalse(user.needsToBeUpdatedFromBackend);
}


- (void)testThatOnInvalidJsonFormatItDoesNotCrash
{
    // given
    NSUUID *uuid = [NSUUID createUUID];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.remoteIdentifier = uuid;
    XCTAssertTrue(user.needsToBeUpdatedFromBackend);
    
    NSDictionary *payload = @{
          @"name" : @6,
          @"id" : [uuid transportString],
          @"email" : @8,
          @"phone" : @5,
          @"accent" : @"boo",
          @"accent_id" : @"foo",
          @"picture" : @55
          };
    
    // when
    [self performIgnoringZMLogError:^{
        [user updateWithTransportData:payload authoritative:YES];
    }];
    
    // then
    XCTAssertFalse(user.needsToBeUpdatedFromBackend);
}

- (void)testPerformanceOfRetrievingSelfUser;
{
    [self measureBlock:^{
        for (size_t i = 0; i < 100000; ++i) {
            (void) [ZMUser selfUserInContext:self.uiMOC];
        }
    }];
}

- (void)testThatItCreatesSessionAndSelfUserCorrectly
{
    //make sure to clear store metadata
    [self.uiMOC setPersistentStoreMetadata:nil forKey:@"SelfUserObjectID"];
    [self.uiMOC setPersistentStoreMetadata:nil forKey:@"SessionObjectID"];
    
    //reset all contexts
    [self resetUIandSyncContextsAndResetPersistentStore:YES];
    WaitForAllGroupsToBeEmpty(0.5);

    [self checkSelfUserIsCreatedCorrectlyInContext:self.uiMOC];
    [self.syncMOC performGroupedBlockAndWait:^{
        [self checkSelfUserIsCreatedCorrectlyInContext:self.syncMOC];
    }];
    
    //when
    // request again
    ZMUser *uiUser = [ZMUser selfUserInContext:self.uiMOC];
    __block NSManagedObjectID *syncUserObjectID = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *syncUser = [ZMUser selfUserInContext:self.syncMOC];
        syncUserObjectID = syncUser.objectID;
    }];
    
    //then
    //Check that the same object is returned
    XCTAssertEqualObjects(uiUser.objectID, syncUserObjectID);
}

- (void)checkSelfUserIsCreatedCorrectlyInContext:(NSManagedObjectContext *)moc
{
    [moc performGroupedBlockAndWait:^{

        //when
        //context is just created
        
        //then
        //check that self user is already created
        NSArray *users = [moc executeFetchRequestOrAssert:[ZMUser sortedFetchRequest]];

        //check that only one user created
        XCTAssertEqual(users.count, 1u);
        ZMUser *selfUser = users.firstObject;
        
        XCTAssertFalse(selfUser.objectID.isTemporaryID);
        
        //check that only one session is created
        NSArray *sessions = [moc executeFetchRequestOrAssert:[ZMSession sortedFetchRequest]];
        XCTAssertEqual(sessions.count, 1u);
        
        //check that session stores user
        ZMSession *session = sessions.firstObject;
        XCTAssertEqual(session.selfUser, selfUser);
        
        //check that we don't store id's by old keys
        XCTAssertNil(moc.userInfo[@"ZMSelfUserManagedObjectID"]);
        XCTAssertNil([moc persistentStoreMetadataForKey:@"SelfUserObjectID"]);
        
        //check that we store session id in user info and metadata
        NSString *moidString = [moc persistentStoreMetadataForKey:@"SessionObjectID"];
        NSURL *moidURL = [NSURL URLWithString:moidString];
        NSManagedObjectID *moid = [moc.persistentStoreCoordinator managedObjectIDForURIRepresentation:moidURL];
        
        //check that we store id's correctly
        XCTAssertEqualObjects(moc.userInfo[@"ZMSessionManagedObjectID"], session.objectID);
        XCTAssertEqualObjects(moid, session.objectID);
        XCTAssertFalse(session.objectID.isTemporaryID);
        
        //check that boxed user is stored in user info
        XCTAssertNotNil(moc.userInfo[@"ZMSelfUser"]);
        
        //when
        //request again
        ZMUser *user = [ZMUser selfUserInContext:moc];
        
        //then
        //check that the same user is returned
        XCTAssertEqualObjects(user, selfUser);
        
        //check that no new session and user is created
        sessions = [moc executeFetchRequestOrAssert:[ZMSession sortedFetchRequest]];
        XCTAssertEqual(sessions.count, 1u);
        users = [moc executeFetchRequestOrAssert:[ZMUser sortedFetchRequest]];
        XCTAssertEqual(users.count, 1u);
    }];
}

- (void)testThatItMatchesObjectsThatNeedToBeUpdatedUpstream
{
    // given
    ZMUser *user = [ZMUser selfUserInContext:self.uiMOC];
    NSPredicate *sut = [ZMUser predicateForObjectsThatNeedToBeUpdatedUpstream];
    
    // when
    [user resetLocallyModifiedKeys:[user keysThatHaveLocalModifications]];
    user.needsToBeUpdatedFromBackend = NO;
    
    // then
    XCTAssertFalse([sut evaluateWithObject:user]);
    
    // when
    [user setLocallyModifiedKeys:[NSSet setWithObject:@"name"]];
    // then
    XCTAssertTrue([sut evaluateWithObject:user]);
    
    // when
    [user resetLocallyModifiedKeys:[user keysThatHaveLocalModifications]];
    // then
    XCTAssertFalse([sut evaluateWithObject:user]);
}

- (void)testThatItMatchesObjectsThatNeedToBeInsertedUpstream
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSPredicate *sut = [ZMUser predicateForObjectsThatNeedToBeInsertedUpstream];
    
    // when
    user.remoteIdentifier = nil;
    // then
    XCTAssertTrue([sut evaluateWithObject:user]);
    
    // when
    user.remoteIdentifier = [NSUUID createUUID];
    // then
    XCTAssertFalse([sut evaluateWithObject:user]);
}


- (void)testThatItSetsNormalizedNameWhenSettingName
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Øyvïnd Øtterssön";
    
    // when
    NSString *normalizedName = user.normalizedName;
    
    // then
    XCTAssertEqualObjects(normalizedName, @"oyvind ottersson");
}


- (void)testThatItSetsNormalizedEmailAddressWhenSettingTheEmailAddress
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.emailAddress = @"Øyvïnd.Øtterssön@example.com";
    
    // when
    NSString *normalizedEmailAddress = user.normalizedEmailAddress;
    
    // then
    XCTAssertEqualObjects(normalizedEmailAddress, @"oyvind.ottersson@example.com");
}


- (void)testThatModifiedDataFieldsCanNeverBeChangedForNormalUser
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Test";

    // when
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqualObjects(user.keysThatHaveLocalModifications, [NSSet set]);
}



- (void)testThatModifiedDataFieldsCanBeModifiedForSelfUser
{
    // given
    ZMUser<ZMEditableUser> *user = [ZMUser selfUserInContext:self.uiMOC];
    user.name = @"Test";
    user.accentColorValue = ZMAccentColorBrightOrange;
    
    // when
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // then
    NSSet *expectedChangedKeys = [NSSet setWithObjects:@"name", @"accentColorValue", nil];
    XCTAssertEqualObjects(user.keysThatHaveLocalModifications, expectedChangedKeys);
}

- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeys
{
    // when
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqual(user.keysTrackedForLocalModifications.count, 0u);
}

- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeysForSelfUser
{
    // given
    NSSet *expected = [NSSet setWithArray:@[@"accentColorValue",
                                            @"emailAddress",
                                            @"previewProfileAssetIdentifier",
                                            @"completeProfileAssetIdentifier",
                                            @"name",
                                            @"phoneNumber",
                                            @"availability",
                                            @"readReceiptsEnabled"]];
    
    // when
    ZMUser *user = [ZMUser selfUserInContext:self.uiMOC];
    XCTAssertNotNil(user);
    
    // then
    XCTAssertEqualObjects(user.keysTrackedForLocalModifications, expected);
}

- (void)testThatClientsRequiringUserAttentionContainsUntrustedClientsWithNeedsToNotifyFlagSet
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser selfUserInContext:self.syncMOC];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        UserClient *trustedClient1 = [self createClientForUser:user createSessionWithSelfUser:NO onMOC:self.syncMOC];
        [selfClient trustClient:trustedClient1];
        trustedClient1.needsToNotifyUser = YES;
        
        UserClient *trustedClient2 = [self createClientForUser:user createSessionWithSelfUser:NO onMOC:self.syncMOC];
        [selfClient trustClient:trustedClient2];
        trustedClient2.needsToNotifyUser = NO;
        
        UserClient *ignoredClient1 = [self createClientForUser:user createSessionWithSelfUser:NO onMOC:self.syncMOC];
        [selfClient ignoreClient:ignoredClient1];
        ignoredClient1.needsToNotifyUser = YES;
        
        UserClient *ignoredClient2 = [self createClientForUser:user createSessionWithSelfUser:NO onMOC:self.syncMOC];
        [selfClient ignoreClient:ignoredClient2];
        ignoredClient2.needsToNotifyUser = NO;
        
        // when
        NSSet<UserClient *> *result = user.clientsRequiringUserAttention;
        
        // then
        NSSet<UserClient *> *expected = [NSSet setWithObjects:ignoredClient1, nil];
        XCTAssertEqualObjects(result, expected);
    }];
}

- (void)testThatCallingRefreshDataMarksItAsToDownload {
    
    [self.syncMOC performBlockAndWait: ^{
        // GIVEN
        ZMUser *user = [ZMUser selfUserInContext:self.syncMOC];
        user.remoteIdentifier = [NSUUID UUID];
        user.needsToBeUpdatedFromBackend = false;
        XCTAssertFalse(user.needsToBeUpdatedFromBackend);
        
        // WHEN
        [user refreshData];
        
        // THEN
        XCTAssertTrue(user.needsToBeUpdatedFromBackend);
    }];
}


-(NSString *)managedByString:(ZMUser *)user {
    return user.managedByWire ? ManagedByWire : ManagedByScim;
}

@end


@implementation ZMUserTests (Connections)

- (void)testThatIsConnectedIsTrueWhenThereIsAnAcceptedConnection
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user;
    
    // then
    XCTAssertTrue(user.isConnected);
    
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertFalse(user.canBeConnected);
}

- (void)testThatIsIgnoreIsTrueWhenThereIsAnIgnoredConnection
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusIgnored;
    connection.to = user;
    
    // then
    XCTAssertTrue(user.isIgnored);
    
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertTrue(user.canBeConnected);
}


- (void)testThatIsBlockedIsTrueWhenThereIsABlockedConnection
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusBlocked;
    connection.to = user;
    
    // then
    XCTAssertTrue(user.isBlocked);
    
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertTrue(user.canBeConnected);
}

//
- (void)testBlockStateReasonValue_WhenAConnectionStatusIsMissingLegalholdConsent
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusBlockedMissingLegalholdConsent;
    connection.to = user;

    // then
    XCTAssertEqual(user.blockState, ZMBlockStateBlockedMissingLegalholdConsent);
    XCTAssertTrue(user.isBlocked);

    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertTrue(user.canBeConnected);
}

- (void)testThatIsPendingBySelfUserIsTrueWhenThereIsAPendingConnection
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusPending;
    connection.to = user;
    
    // then
    XCTAssertTrue(user.isPendingApprovalBySelfUser);
    
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertTrue(user.canBeConnected);
}


- (void)testThatIsPendingByOtherUserIsTrueWhenThereIsASentConnection
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusSent;
    connection.to = user;
    
    // then
    XCTAssertTrue(user.isPendingApprovalByOtherUser);
    
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertFalse(user.canBeConnected);
}

- (void)testThatAWirelessUserCanNotBeConnectedTo
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.expiresAt = [NSDate date];
    
    // then
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    
    XCTAssertFalse(user.canBeConnected);
    XCTAssertTrue(user.isWirelessUser);
}

- (void)testThatConnectionsValuesAreFalseWhenThereIsNotAConnectionToTheSelfUser
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertFalse(user.isConnected);
    XCTAssertFalse(user.isBlocked);
    XCTAssertFalse(user.isIgnored);
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssertFalse(user.isPendingApprovalBySelfUser);
    XCTAssertTrue(user.canBeConnected);
}

- (void)testThatOneToOneConversationReturnSelfConversationForTheSelfUser
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMConversation *selfConversation = [ZMConversation selfConversationInContext:self.uiMOC];
    
    // then
    XCTAssertNotNil(selfUser.oneToOneConversation);
    XCTAssertEqual(selfConversation, selfUser.oneToOneConversation);
}

- (void)testThatItReturnsTheOneToOneConversationToAnUser
{
    // given
    ZMUser *connectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *unconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *oneToOne = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusIgnored;
    connection.conversation = oneToOne;
    connection.to = connectedUser;
    
    // then
    XCTAssertNil(unconnectedUser.oneToOneConversation);
    XCTAssertEqual(oneToOne, connectedUser.oneToOneConversation);
}

@end


@implementation ZMUserTests (Validation)

- (void)testThatItRejectsANameThatIsOnly1CharacterLong
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Original name";
    [self.uiMOC saveOrRollback];
    
    // when
    user.name = @" A";
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.name, @"Original name");
}

- (void)testThatItTrimmsTheNameForLeadingAndTrailingWhitespace;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Abe";
    [self.uiMOC saveOrRollback];
    
    // when
    user.name = @" \tasdfad \t";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(user.name, @"asdfad");
}

- (void)testThatItRollsBackIfTheNameIsTooLong;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Short Name";
    [self.uiMOC saveOrRollback];
    
    // when
    user.name = [@"" stringByPaddingToLength:200 withString:@"Long " startingAtIndex:0];
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.name, @"Short Name");
}

- (void)testThatItReplacesNewlinesAndTabWithSpacesInTheName;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Name";
    [self.uiMOC saveOrRollback];
    
    // when
    user.name = @"\tA\tB \tC\t\rD\r \nE";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(user.name, @"A B  C  D   E");
}

- (void)testThatItDoesNotValidateTheNameOnSyncContext_1;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"Name";
        [self.syncMOC saveOrRollback];
        
        // when
        user.name = @"\tA\tB \tC\t\rD\r \nE";
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.name, @"\tA\tB \tC\t\rD\r \nE");
    }];
}

- (void)testThatItDoesNotValidateTheNameOnSyncContext_2;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = @"Name";
        [self.syncMOC saveOrRollback];
        NSString *veryLongName = [@"" stringByPaddingToLength:300 withString:@"Long " startingAtIndex:0];
        
        // when
        user.name = veryLongName;
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.name, veryLongName);
    }];
}

- (void)testThatExtremeCombiningCharactersAreRemovedFromTheName
{
    // GIVEN
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    
    // WHEN
    user.name = @"ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂";
    
    // THEN
    XCTAssertEqualObjects(user.name, @"test̻̟̙");
}

- (void)testThatItLimitsTheAccentColorToAValidRange;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.accentColorValue = ZMAccentColorBrightYellow;
    [self.uiMOC saveOrRollback];
    XCTAssertEqual(user.accentColorValue, ZMAccentColorBrightYellow);
    
    // when
    user.accentColorValue = ZMAccentColorUndefined;
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertGreaterThanOrEqual(user.accentColorValue, ZMAccentColorMin);
    XCTAssertLessThanOrEqual(user.accentColorValue, ZMAccentColorMax);
    
    // when
    user.accentColorValue = (ZMAccentColor) (ZMAccentColorMax + 1);
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertGreaterThanOrEqual(user.accentColorValue, ZMAccentColorMin);
    XCTAssertLessThanOrEqual(user.accentColorValue, ZMAccentColorMax);
}

- (void)testThatItDoesNotLimitTheAccentColorOnTheSyncContext;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.accentColorValue = ZMAccentColorBrightYellow;
        [self.syncMOC saveOrRollback];
        XCTAssertEqual(user.accentColorValue, ZMAccentColorBrightYellow);
        
        // when
        user.accentColorValue = ZMAccentColorUndefined;
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqual(user.accentColorValue, ZMAccentColorUndefined);
    }];
}

- (void)testThatItLimitsTheNameLength;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Tester Name";
    [self.uiMOC saveOrRollback];
    XCTAssertEqualObjects(user.name, @"Tester Name");
    NSString *veryLongName = [@"" stringByPaddingToLength:140 withString:@"zeta" startingAtIndex:0];
    
    // when
    user.name = veryLongName;
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.name, @"Tester Name");
}

- (void)testThatItLimitsTheEmailAddressLength;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.emailAddress = @"tester@example.com";
    [self.uiMOC saveOrRollback];
    XCTAssertEqualObjects(user.emailAddress, @"tester@example.com");
    NSString *veryLongName = [@"" stringByPaddingToLength:120 withString:@"zeta" startingAtIndex:0];
    NSString *veryLongEmailAddress = [veryLongName stringByAppendingString:@"@example.com"];
    
    // when
    user.emailAddress = veryLongEmailAddress;
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.emailAddress, @"tester@example.com");
}

- (void)testThatItTrimsWhiteSpaceInTheEmailAddress;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *original = @"tester@example.com";
    user.emailAddress = original;
    [self.uiMOC saveOrRollback];
    
    // when
    user.emailAddress = @"  tester@example.com\t\n";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(user.emailAddress, original);
}

- (void)testThatItFailsOnAnEmailAddressWithWhiteSpace;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *original = @"tester@example.com";
    user.emailAddress = original;
    [self.uiMOC saveOrRollback];
    XCTAssertEqualObjects(user.emailAddress, original);
    
    // when
    user.emailAddress = @"tes ter@example.com";
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.emailAddress, original);

    // when
    user.emailAddress = @"tester@exa\tmple.com";
    [self performIgnoringZMLogError:^{
        [self.uiMOC saveOrRollback];
    }];
    
    // then
    XCTAssertEqualObjects(user.emailAddress, original);
}

static NSString * const usernameValidCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'*+-/=?^_`{|}~abcdefghijklmnopqrstuvwxyz0123456789";
static NSString * const usernameValidCharactersLowercased = @"abcdefghijklmnopqrstuvwxyz!#$%&'*+-/=?^_`{|}~abcdefghijklmnopqrstuvwxyz0123456789";

static NSString * const domainValidCharacters = @"abcdefghijklmnopqrstuvwxyz-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static NSString * const domainValidCharactersLowercased = @"abcdefghijklmnopqrstuvwxyz-0123456789abcdefghijklmnopqrstuvwxyz";

- (void)testThatItAcceptsAValidEmailAddress
{
    // C.f. <https://en.wikipedia.org/wiki/Email_address#Valid_email_addresses>
    
    NSDictionary *validEmailAddresses =
    @{
      @"niceandsimple@example.com" : @"niceandsimple@example.com",
      @"very.common@example.com" : @"very.common@example.com",
      @"a.little.lengthy.but.fine@dept.example.com" : @"a.little.lengthy.but.fine@dept.example.com",
      @"disposable.style.email.with+symbol@example.com" : @"disposable.style.email.with+symbol@example.com",
      @"other.email-with-dash@example.com" : @"other.email-with-dash@example.com",
      //      @"user@localserver",
      @"abc.\"defghi\".xyz@example.com" : @"abc.\"defghi\".xyz@example.com",
      @"\"abcdefghixyz\"@example.com" : @"\"abcdefghixyz\"@example.com",
      @"a@b.c.example.com" : @"a@b.c.example.com",
      @"a@3b.c.example.com": @"a@3b.c.example.com",
      @"a@b-c.d.example.com" : @"a@b-c.d.example.com",
      @"a@b-c.d-c.example.com" : @"a@b-c.d-c.example.com",
      @"a@b3-c.d4.example.com" : @"a@b3-c.d4.example.com",
      @"a@b-4c.d-c4.example.com" : @"a@b-4c.d-c4.example.com",
      @"Meep Møøp <Meep.Moop@example.com>" : @"meep.moop@example.com",
      @"=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@example.com>" : @"keld@example.com",
      @"=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=@example.com" : @"=?iso-8859-1?q?keld_j=f8rn_simonsen?=@example.com",
      @"\"Meep Møøp\" <Meep.Moop@example.com>" : @"meep.moop@example.com",
      @"Meep   Møøp  <Meep.Moop@EXample.com>" : @"meep.moop@example.com",
      @"Meep \"_the_\" Møøp <Meep.Moop@ExAmple.com>" : @"meep.moop@example.com",
      @"   whitespace@example.com    " : @"whitespace@example.com",
      @"मानक \"हिन्दी\" <manaka.hindi@example.com>" : @"manaka.hindi@example.com",

//      these cases are also possible but are very unlikely to appear
//      currently they don't pass validation
//      @"\"very.unusual.@.unusual.com\"@example.com" : @"\"very.unusual.@.unusual.com\"@example.com",
//      @"Some Name <\"very.unusual.@.unusual.com\"@example.com>" : @"\"very.unusual.@.unusual.com\"@example.com"
      };
    
    for (NSString *valid in validEmailAddresses) {
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        NSString *original = @"tester@example.com";
        user.emailAddress = original;
        [self.uiMOC saveOrRollback];
        XCTAssertEqualObjects(user.emailAddress, original);
        
        // when
        user.emailAddress = valid;
        [self.uiMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.emailAddress, validEmailAddresses[valid]);
    }
}

- (void)testThatItFailsOnAnInvalidEmailAddress
{
    // C.f. <https://en.wikipedia.org/wiki/Email_address#Valid_email_addresses>
    
    NSArray *invalidEmailAddresses =
    @[@"Abc.example.com", // (an @ character must separate the local and domain parts)
      @"A@b@c@example.com", // (only one @ is allowed outside quotation marks)
      @"a\"b(c)d,e:f;g<h>i[j\\k]l@example.com", // (none of the special characters in this local part is allowed outside quotation marks)
      @"just\"not\"right@example.com", // (quoted strings must be dot separated or the only element making up the local-part)
      @"this is\"not\\allowed@example.com", // (spaces, quotes, and backslashes may only exist when within quoted strings and preceded by a backslash)
      @"this\\ still\\\"not\\\\allowed@example.com", // (even if escaped (preceded by a backslash), spaces, quotes, and backslashes must still be contained by quotes)
      @"tester@example..com", // double dot before @
      @"foo..tester@example.com", // double dot after @
      @"",
      usernameValidCharactersLowercased,
      @"a@b",
      @"a@b3",
      @"a@b.c-",
      //      @"a@3b.c", //unclear why this should be not valid
      @"two words@something.org",
      @"\"Meep Moop\" <\"The =^.^= Meeper\"@x.y",
      @"mailbox@[11.22.33.44]",
      @"some prefix with <two words@example.com>",
      @"x@something_odd.example.com",
      @"x@host.with?query=23&parameters=42",
      @"some.mail@host.with.port:12345",
      @"comments(inside the address)@are(actually).not(supported, but nobody uses them anyway)",
      @"\"you need to close quotes@proper.ly",
      @"\"you need\" <to.close@angle-brackets.too",
      @"\"you need\" >to.open@angle-brackets.first",
      @"\"you need\" <to.close@angle-brackets>.right",
      @"some<stran>ge@example.com",
      @"Mr. Stranger <some<stran>ge@example.com>",
      @"<Meep.Moop@EXample.com>"
      ];

    
    
    for (NSString *invalid in invalidEmailAddresses) {
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        NSString *original = @"tester@example.com";
        user.emailAddress = original;
        [self.uiMOC saveOrRollback];
        XCTAssertEqualObjects(user.emailAddress, original);
        
        // when
        user.emailAddress = invalid;
        [self performIgnoringZMLogError:^{
            [self.uiMOC saveOrRollback];
        }];
    
        // then
        XCTAssertEqualObjects(user.emailAddress, original, @"Tried to set invalid \'%@\'", invalid);
    }
}

- (void)testThatItDoesNotValidateTheEmailAddressOnTheSyncContext;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.emailAddress = @"tester@example.com";
        [self.syncMOC saveOrRollback];
        
        // when
        user.emailAddress = @" tester\t  BLA \\\"";
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.emailAddress, @" tester\t  BLA \\\"");
    }];
}

- (void)testThatItAcceptsAValidPhoneNumber
{
    NSArray *validPhoneNumbers =
    @[@"123456", // short
      @"123456789012345678", // normal length
      @"+4915233336668",
      @"+49 152 3333 6668",
      @"+49 (0) 152 3333 6668",
      @"(152) 3333-6668",
      @"415.456.456",
      @"+1 415.456.456",
      @"00 1 415.456.456"];
    
    
    for (NSString *valid in validPhoneNumbers) {
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        NSString *original = @"12345678";
        user.phoneNumber = original;
        [self.uiMOC saveOrRollback];
        XCTAssertEqualObjects(user.phoneNumber, original);
        
        // when
        user.phoneNumber = valid;
        [self.uiMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.phoneNumber, valid, @"Tried to set valid \'%@\'", valid);
    }
}

- (void)testThatItDoesNotValidateThePhoneNumberOnTheSyncContext;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.phoneNumber = @"12345678";
        [self.syncMOC saveOrRollback];
        
        // when
        user.phoneNumber = @" tester\t  BLA \\\"";
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqualObjects(user.phoneNumber, @" tester\t  BLA \\\"");
    }];
}

- (void)testThatItStaticallyDoesNotValidateAShortCode
{
    // given
    NSString *code = ShortPhoneCode;
    
    // when
    XCTAssertFalse([ZMUser validatePhoneVerificationCode:&code error:nil]);
}

- (void)testThatItStaticallyDoesNotValidateALongCode
{
    // given
    NSString *code = LongPhoneCode;
    
    // when
    XCTAssertFalse([ZMUser validatePhoneVerificationCode:&code error:nil]);
}

- (void)testThatItStaticallyValidatesACodeOfTheRightLength
{
    // given
    NSString *phone = ValidPhoneCode;
    
    // when
    XCTAssertTrue([ZMUser validatePhoneVerificationCode:&phone error:nil]);
}

- (void)testThatItStaticallyDoesNotValidateAnEmptyOrNilCode
{
    // given
    NSString *phone = @"";
    // when
    XCTAssertFalse([ZMUser validatePhoneVerificationCode:&phone error:nil]);
    
    phone = nil;
    XCTAssertFalse([ZMUser validatePhoneVerificationCode:&phone error:nil]);
}

- (void)testThatItStaticallyDoesNotValidateEmptyOrNilPhoneNumber
{
    //given
    NSString *phoneNumber = @"";
    
    //when
    XCTAssertFalse([ZMUser validatePhoneNumber:&phoneNumber error:nil]);
    
    phoneNumber = nil;
    XCTAssertFalse([ZMUser validatePhoneNumber:&phoneNumber error:nil]);
}

- (void)testThatItStaticallyDoesValidateValidPhoneNumbers
{
    //given
    for (NSString *number in self.validPhoneNumbers) {
        NSString *phoneNumber = number;
        XCTAssertTrue([ZMUser validatePhoneNumber:&phoneNumber error:nil], @"Phone number %@ should be valid", phoneNumber);
    }
}

- (void)testThatItStaticallyDoesNotValidatePhoneNumberWithInvalidChars
{
    NSArray *invalidCharactes = @[@"*", @";", @"#", @"[", @"]", @"~"];
    for (NSString *invalidChar in invalidCharactes) {
        NSString *phoneNumber = [ValidPhoneNumber stringByAppendingString:invalidChar];
        XCTAssertFalse([ZMUser validatePhoneNumber:&phoneNumber error:nil], @"Phone number %@ should be invalid", phoneNumber);
    }
}

- (void)testThatItStaticallyDoesNotValidateShortPhoneNumbers
{
    for (NSString *number in self.shortPhoneNumbers) {
        NSString *phoneNumber = number;
        XCTAssertFalse([ZMUser validatePhoneNumber:&phoneNumber error:nil], @"Phone number %@ should be invalid", phoneNumber);
    }
}

- (void)testThatItStaticallyDoesNotValidateLongPhoneNumbers
{
    for (NSString *number in self.longPhoneNumbers) {
        NSString *phoneNumber = number;
        XCTAssertFalse([ZMUser validatePhoneNumber:&phoneNumber error:nil], @"Phone number %@ should be invalid", phoneNumber);
    }
}

- (void)testThatItDoesNotValidateAShortPassword
{
    // given
    NSString *password = ShortPassword;
    
    // when
    XCTAssertFalse([ZMUser validatePassword:&password error:nil]);
}

- (void)testThatItDoesNotValidateLongPassword
{
    // given
    NSString *password = LongPassword;
    
    // when
    XCTAssertFalse([ZMUser validatePassword:&password error:nil]);
}

- (void)testThatItValidatesAValidPassword
{
    // given
    NSString *password = ValidPassword;
    
    // when
    XCTAssertTrue([ZMUser validatePassword:&password error:nil]);
}


@end



@implementation ZMUserTests (KeyValueObserving)

- (void)testThatItRecalculatesIsBlockedWhenConnectionChanges
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user1;
    
    XCTAssertFalse(user1.isBlocked);
    // expect

    [self keyValueObservingExpectationForObject:user1 keyPath:@"isBlocked" expectedValue:nil];
    
    // when
    connection.status = ZMConnectionStatusBlocked;

    // then
    XCTAssertTrue(user1.isBlocked);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesBlockStateReasonExposureWhenConnectionChanges
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user1;

    XCTAssertEqual(user1.blockState, ZMBlockStateNone);

    // expect

    [self keyValueObservingExpectationForObject:user1 keyPath:@"blockStateReason" expectedValue:nil];

    // when
    connection.status = ZMConnectionStatusBlockedMissingLegalholdConsent;

    // then
    XCTAssertEqual(user1.blockState, ZMBlockStateBlockedMissingLegalholdConsent);
    XCTAssertTrue(user1.isBlocked);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesIsIgnoredWhenConnectionChanges
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user1;
    
    XCTAssertFalse(user1.isIgnored);
    // expect
    
    [self keyValueObservingExpectationForObject:user1 keyPath:@"isIgnored" expectedValue:nil];
    
    // when
    connection.status = ZMConnectionStatusIgnored;
    
    // then
    XCTAssertTrue(user1.isIgnored);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesIsPendingApprovalBySelfUserWhenConnectionChanges
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusPending;
    connection.to = user1;
    
    XCTAssertTrue(user1.isPendingApprovalBySelfUser);
    // expect
    
    [self keyValueObservingExpectationForObject:user1 keyPath:@"isPendingApprovalBySelfUser" expectedValue:nil];
    
    // when
    connection.status = ZMConnectionStatusAccepted;
    
    // then
    XCTAssertFalse(user1.isPendingApprovalBySelfUser);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesIsPendingApprovalByOtherUsersWhenConnectionChanges
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusSent;
    connection.to = user;
    
    XCTAssertTrue(user.isPendingApprovalByOtherUser);
    // expect
    
    [self keyValueObservingExpectationForObject:user keyPath:@"isPendingApprovalByOtherUser" expectedValue:nil];
    
    // when
    connection.status = ZMConnectionStatusAccepted;
    
    // then
    XCTAssertFalse(user.isPendingApprovalByOtherUser);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end
    

@implementation ZMUserTests (DisplayName)

- (void)testThatItReturnsCorrectUserNameForService
{
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"User Name";
    user.providerIdentifier = [[NSUUID UUID] transportString];
    user.serviceIdentifier = [[NSUUID UUID] transportString];
    
    XCTAssertTrue(user.isServiceUser);
    XCTAssertEqualObjects(user.name, @"User Name");
}

- (void)testThatItReturnsCorrectInitials
{
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"User Name";
    
    XCTAssertEqualObjects(user.initials, @"UN");
}

- (void)testThatTheUserNameIsCopied
{
    // given
    NSString *originalName = @"Will";
    NSMutableString *name = [originalName mutableCopy];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    user.name = name;
    [name appendString:@"iam"];
    
    // then
    XCTAssertEqualObjects(user.name, originalName);
}

@end


@implementation ZMUserTests (Trust)

- (void)testThatItReturns_Trusted_NO_WhenThereAreNoClients
{
    // given
    ZMUser *user = [self userWithClients:0 trusted:NO];
    
    // when
    BOOL isTrusted = user.isTrusted;
    
    //then
    XCTAssertFalse(isTrusted);
}


- (void)testThatItReturns_Trusted_YES_WhenThereAreTrustedClients
{
    // given
    ZMUser *user = [self userWithClients:1 trusted:YES];
    
    // when
    BOOL isTrusted = user.isTrusted;
    
    //then
    XCTAssertTrue(isTrusted);
}

- (void)testThatItReturns_Trusted_NO_WhenThereAreNoTrustedClients
{
    // given
    ZMUser *user = [self userWithClients:1 trusted:NO];
    
    // when
    BOOL isTrusted = user.isTrusted;
    
    //then
    XCTAssertFalse(isTrusted);
}


- (void)testThatItReturns_UnTrusted_NO_WhenThereAreNoClients
{
    // given
    ZMUser *user = [self userWithClients:0 trusted:YES];
    
    // when
    BOOL isTrusted = !user.isTrusted;
    
    //then
    XCTAssertFalse(isTrusted);
}


- (void)testThatItReturns_UnTrusted_YES_WhenThereAreUnTrustedClients
{
    // given
    ZMUser *user = [self userWithClients:1 trusted:NO];
    
    // when
    BOOL untrusted = !user.isTrusted;
    
    //then
    XCTAssertTrue(untrusted);
}

- (void)testThatItReturns_UnTrusted_NO_WhenThereAreNoUnTrustedClients
{
    // given
    ZMUser *user = [self userWithClients:1 trusted:YES];
    
    // when
    BOOL untrusted = !user.isTrusted;
    
    //then
    XCTAssertFalse(untrusted);
}

@end

