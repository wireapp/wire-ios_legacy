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


#import "ZMSTestDetection.h"

NSString * const zm_testing_environment_variable_name = @"ZM_TESTING";


BOOL zm_isTesting(void) {
    
    NSString *value = [NSProcessInfo processInfo].environment[zm_testing_environment_variable_name];
    return value != nil && [value isEqualToString:@"1"];
}
