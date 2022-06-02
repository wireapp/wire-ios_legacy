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


#import "ZMUser+Testing.h"

@implementation ZMUser (Testing)

- (void)assertMatchesUser:(MockUser *)user failureRecorder:(ZMTFailureRecorder *)failureRecorder;
{
    if (user == nil) {
        [failureRecorder recordFailure:@"ZMUser is <nil>"];
        return;
    }
    
    if(self.isSelfUser) {
        FHAssertEqualObjects(failureRecorder, self.emailAddress, user.email);
        FHAssertEqualObjects(failureRecorder, self.phoneNumber, user.phone);
    }
    
    FHAssertEqualObjects(failureRecorder, self.name, user.name);
    FHAssertEqualObjects(failureRecorder, self.remoteIdentifier, [user.identifier UUID]);
    FHAssertEqualObjects(failureRecorder, self.completeProfileAssetIdentifier, user.completeProfileAssetIdentifier);
}

@end
