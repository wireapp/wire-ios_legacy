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


#import <XCTest/XCTest.h>
#import "ZMSTestDetection.h"

@interface ZMSTestDetectionTests : XCTestCase

@property (nonatomic) BOOL testVariableWasOn;

@end

@implementation ZMSTestDetectionTests

- (void)setUp {
    char *var = getenv(zm_testing_environment_variable_name.UTF8String);
    self.testVariableWasOn = var != 0 && strcmp(var, "1") == 0;
}

- (void)tearDown {
    setenv(zm_testing_environment_variable_name.UTF8String, self.testVariableWasOn ? "1" : "0", 1);
}


- (void)testThatItIsNotInATestWhenTheEnvironmentVariableIsOff {
    
    XCTAssertFalse(zm_isTesting());
}

- (void)testThatItIsInATestWhenTheEnvironmentVariableIsOn {

    setenv(zm_testing_environment_variable_name.UTF8String, "1", 1);
    XCTAssertTrue(zm_isTesting());
}

@end
