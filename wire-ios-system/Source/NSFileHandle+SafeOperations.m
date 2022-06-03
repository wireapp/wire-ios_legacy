//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

#import "NSFileHandle+SafeOperations.h"

@implementation NSFileHandle (SafeOperations)

-(BOOL)wr_writeData:(NSData *)data error:(__autoreleasing NSError **)error
{
    @try {
        [self writeData:data];
        return YES;
    } @catch(NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

-(BOOL)wr_synchronizeFile:(NSError * _Nullable __autoreleasing *)error
{
    @try {
        [self synchronizeFile];
        return YES;
    } @catch(NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
