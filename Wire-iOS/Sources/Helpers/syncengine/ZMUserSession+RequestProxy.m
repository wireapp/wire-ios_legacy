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


#import "ZMUserSession+RequestProxy.h"

@interface ZMProxyRequest (ZiphyRequestIdentifier) <ZiphyRequestIdentifier>
@end

@implementation ZMProxyRequest (ZiphyRequestIdentifier)
@end

@implementation ZMUserSession (RequestProxy)

- (id<ZiphyRequestIdentifier>)doRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
{
    // Removing the https://host part from the given URL, so WireSyncEngine can prepend it with the Wire giphy proxy host
    NSString *fullHost = [NSString stringWithFormat:@"%@://%@", request.URL.scheme, request.URL.host];
    NSString *URLString = [request.URL absoluteString];
    URLString = [URLString stringByReplacingOccurrencesOfString:fullHost withString:@""];
    
    return [self doRequestWithPath:URLString method:ZMMethodGET type:ProxiedRequestTypeGiphy completionHandler:completionHandler];
}

- (void)cancelRequestWithRequestIdentifier:(id<ZiphyRequestIdentifier>)requestIdentifier
{
    if ([(id)requestIdentifier isKindOfClass:ZMProxyRequest.class]) {
        [self cancelProxiedRequest:(ZMProxyRequest *)requestIdentifier];
    }
}

- (ZMProxyRequest *)doRequestWithPath:(NSString *)path method:(ZMTransportRequestMethod)method type:(ProxiedRequestType)type completionHandler:(void (^ __nonnull)(NSData * __nullable, NSURLResponse * __nullable, NSError * __nullable))completionHandler;
{
    return [self proxiedRequestWithPath:path method:method type:type callback:completionHandler];
}

@end
