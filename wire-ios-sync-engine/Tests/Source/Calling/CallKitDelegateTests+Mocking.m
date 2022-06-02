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

#import "CallKitDelegateTests+Mocking.h"

@import WireSyncEngine;
@import OCMock;

@implementation CallKitDelegateTestsMocking

+ (CXCall *)mockCallWithUUID:(NSUUID *)uuid outgoing:(BOOL)outgoing
{
    id mockCall = [OCMockObject niceMockForClass:CXCall.class];
    
    [(CXCall *)[[mockCall stub] andReturn:uuid] UUID];
    [(CXCall *)[[mockCall stub] andReturnValue:@(outgoing)] isOutgoing];
    
    return mockCall;
}

+ (void)stopMockingMock:(NSObject *)mock
{
    [(OCMockObject* )mock stopMocking];
}

@end
