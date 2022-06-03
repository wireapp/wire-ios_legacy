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


@import WireTesting;
@import WireUtilities;



@interface ZMMobileProvisionParserTests : ZMTBaseTest
@end



@implementation ZMMobileProvisionParserTests

- (void)testThatItParsesAppStoreSandbox;
{
    [self assertMatchingTeam:ZMProvisionTeamAppStore apsEnvironment:ZMAPSEnvironmentUnknown forProfileNamed:@"appstore-sandbox"];
}

- (void)testThatItParsesEnterpriseProduction;
{
    [self assertMatchingTeam:ZMProvisionTeamEnterprise apsEnvironment:ZMAPSEnvironmentProduction forProfileNamed:@"enterprise-production"];
}

- (void)testThatItParsesEnterpriseSandbox;
{
    [self assertMatchingTeam:ZMProvisionTeamEnterprise apsEnvironment:ZMAPSEnvironmentSandbox forProfileNamed:@"enterprise-sandbox"];
}

#pragma mark - Helper

- (void)assertMatchingTeam:(ZMProvisionTeam)team apsEnvironment:(ZMAPSEnvironment)environment forProfileNamed:(NSString *)profileName
{
    // given
    NSURL *profileURL = [self urlForBinaryProvisioningFileFromXMLWithName:profileName];
    
    // when
    ZMMobileProvisionParser *parser = [[ZMMobileProvisionParser alloc] initWithURL:profileURL];
    
    // then
    XCTAssertEqual(parser.team, team);
    XCTAssertEqual(parser.APSEnvironment, environment);
    XCTAssertTrue([NSFileManager.defaultManager removeItemAtURL:profileURL error:nil]);
}

- (NSURL *)urlForBinaryProvisioningFileFromXMLWithName:(NSString *)xmlPListFileName
{
    NSURL *xmlURL = [self fileURLForResource:xmlPListFileName extension:@"xml"];
    
    NSError *error;
    NSString *xml = [NSString stringWithContentsOfURL:xmlURL encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:xml format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    XCTAssertNil(error);
    
    NSURL *dataURL = [xmlURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"profile.mobileprovision"];
    XCTAssertTrue([data writeToURL:dataURL atomically:YES]);
    
    return dataURL;
}

@end
