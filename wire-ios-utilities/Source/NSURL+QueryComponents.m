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


#import "NSURL+QueryComponents.h"

@implementation NSURL (ZMQueryComponents)

- (NSDictionary *)zm_queryComponents;
{
    // TODO: use NSURLComponents here on 10.10
    
    // Parse the query:
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    if (self.query != nil) {
        for (NSString *comp in [self.query componentsSeparatedByString:@"&"]) {
            NSArray *components = [comp componentsSeparatedByString:@"="];
            if(components.count > 2) {
                return @{};
            }
            NSString *key = components.firstObject;
            NSString *value = components.count > 1 ? components.lastObject : @"";
            query[key] = value;
        }
    }
    return query;
}

@end
