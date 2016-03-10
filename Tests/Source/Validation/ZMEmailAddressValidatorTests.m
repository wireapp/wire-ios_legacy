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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import "MessagingTest.h"
#import "ZMEmailAddressValidator.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"

static NSString * const usernameValidCharacters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'*+-/=?^_`{|}~abcdefghijklmnopqrstuvwxyz0123456789";
static NSString * const usernameValidCharactersLowercased = @"abcdefghijklmnopqrstuvwxyz!#$%&'*+-/=?^_`{|}~abcdefghijklmnopqrstuvwxyz0123456789";

static NSString * const domainValidCharacters = @"abcdefghijklmnopqrstuvwxyz-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
static NSString * const domainValidCharactersLowercased = @"abcdefghijklmnopqrstuvwxyz-0123456789abcdefghijklmnopqrstuvwxyz";

@interface ZMEmailAddressValidatorTests : MessagingTest

@end

@implementation ZMEmailAddressValidatorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatValidEmailsPassValidation
{
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
      @"a@b.c" : @"a@b.c",
      @"a@3b.c": @"a@3b.c",
      @"a@b-c.d" : @"a@b-c.d",
      @"a@b-c.d-c" : @"a@b-c.d-c",
      @"a@b3-c.d4" : @"a@b3-c.d4",
      @"a@b-4c.d-c4" : @"a@b-4c.d-c4",
      @"Meep Møøp <Meep.Moop@EMail.me>" : @"meep.moop@example.com",
      @"=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@some.domain>" : @"keld@example.com",
      @"=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=@some.domain" : @"=?iso-8859-1?q?keld_j=f8rn_simonsen?=@example.com",
      @"\"Meep Møøp\" <Meep.Moop@EMail.me>" : @"meep.moop@example.com",
      @"Meep   Møøp  <Meep.Moop@EMail.me>" : @"meep.moop@example.com",
      @"Meep \"_the_\" Møøp <Meep.Moop@EMail.me>" : @"meep.moop@example.com",
      @"   white@space.com    " : @"white@example.com",
      @"मानक \"हिन्दी\" <manaka.hindi@langua.ge>" : @"manaka.hindi@example.com",
      
      //these cases are also possible but are very unlikely to appear
      //currently they don't pass validation
      //      @"\"very.unusual.@.unusual.com\"@example.com" : @"\"very.unusual.@.unusual.com\"@example.com",
      //      @"Some Name <\"very.unusual.@.unusual.com\"@example.com>" : @"\"very.unusual.@.unusual.com\"@example.com"
      };
    
    BOOL isValid;
    NSError *error;
    NSMutableArray *validatedEmails = [NSMutableArray new];
    for (NSString *email in validEmailAddresses) {
        NSString *validatedEmail = email;
        isValid = [ZMEmailAddressValidator validateValue:&validatedEmail error:&error];
        [validatedEmails addObject:validatedEmail];
        XCTAssertTrue(isValid);
        XCTAssertNil(error);
    }
    AssertArraysContainsSameObjects(validatedEmails, validEmailAddresses.allValues);
}

- (void)testThatInvalidEmailsDoNotPassValidation
{
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
      @"some prefix with <two words@something.org>",
      @"x@something_odd.com",
      @"x@host.with?query=23&parameters=42",
      @"some.mail@host.with.port:12345",
      @"comments(inside the address)@are(actually).not(supported, but nobody uses them anyway)",
      @"\"you need to close quotes@proper.ly",
      @"\"you need\" <to.close@angle-brackets.too",
      @"\"you need\" >to.open@angle-brackets.first",
      @"\"you need\" <to.close@angle-brackets>.right",
      @"some<stran>ge@email.com",
      @"Mr. Stranger <some<stran>ge@email.com>",
      @"<Meep.Moop@EMail.me>"
      ];
    
    BOOL isValid;
    NSError *error;
    for (NSString *email in invalidEmailAddresses) {
        NSString *validatedEmail = email;
        isValid = [ZMEmailAddressValidator validateValue:&validatedEmail error:&error];
        XCTAssertFalse(isValid);
        XCTAssertNotNil(error);
    }
}


@end
