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


#import "ZMTransportCodec.h"


@implementation ZMTransportCodec

+ (id<ZMTransportData>)interpretResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *)error;
{
    if ((data == nil) || (error != nil) || response.statusCode >= 500) {
        return nil;
    }
    
    // checks that the type is the expected one
    NSString *contentType = [[response allHeaderFields] objectForKey:@"Content-Type"];
    if(!contentType) {
        return nil;
    }
    NSString *firstToken = [contentType componentsSeparatedByString:@";"][0];
    if(! [[firstToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:[ZMTransportCodec encodedContentType]]) {
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}



+ (NSData *)encodedTransportData:(id<ZMTransportData>)object
{
    if (!object) {
        return [NSData data];
    }
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)object;
        return [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSError *error;
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
}

+ (NSString *)encodedContentType
{
    return @"application/json";
}

@end



@implementation NSDictionary (TransportData)
@end



@implementation NSArray (TransportData)
@end
