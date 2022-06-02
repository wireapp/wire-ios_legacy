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


#import "ZMTransportData.h"

@implementation NSDictionary (ZMTransportData)

- (NSDictionary *)asDictionary;
{
    return self;
}
- (NSArray *)asArray;
{
    return nil;
}

- (id)asTransportData
{
    return self;
}

@end

@implementation NSArray (ZMTransportData)

- (NSDictionary *)asDictionary;
{
    return nil;
}
- (NSArray *)asArray;
{
    return self;
}

- (id)asTransportData
{
    return self;
}

@end

@implementation NSString (ZMTransportData)

- (NSDictionary *)asDictionary
{
    return [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (NSArray *)asArray
{
    return nil;
}

- (id)asTransportData
{
    return self;
}

@end
