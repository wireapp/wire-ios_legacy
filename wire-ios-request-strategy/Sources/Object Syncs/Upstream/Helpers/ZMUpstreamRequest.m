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


#import "ZMUpstreamRequest.h"


@implementation ZMUpstreamRequest

- (instancetype)initWithKeys:(NSSet *)keys transportRequest:(ZMTransportRequest *)transportRequest;
{
    return [self initWithKeys:keys transportRequest:transportRequest userInfo:nil];
}

- (instancetype)initWithKeys:(NSSet *)keys transportRequest:(ZMTransportRequest *)transportRequest userInfo:(NSDictionary *)info;
{
    self = [super init];
    if (self) {
        _keys = [keys copy] ?: [NSSet set];
        _transportRequest = transportRequest;
        _userInfo = [info copy] ?: [NSDictionary dictionary];
    }
    return self;
}


- (instancetype)initWithTransportRequest:(ZMTransportRequest *)transportRequest;
{
    self = [self initWithKeys:nil transportRequest:transportRequest userInfo:nil];
    return self;
}

- (NSString *)debugDescription;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p>", self.class, self];
    if (self.keys.count == 0) {
        [description appendString:@" no keys"];
    } else {
        [description appendFormat:@" keys = {%@}", [self.keys.allObjects componentsJoinedByString:@", "]];
    }
    [description appendString:@", transport request: "];
    [description appendString:self.transportRequest.debugDescription];
    return description;
}

@end

