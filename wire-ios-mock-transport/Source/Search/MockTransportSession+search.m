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

@import WireTransport;
@import WireTesting;
@import WireProtos;
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockAsset.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockTransportSession (Search)

/// handles /search/contacts/
- (ZMTransportResponse *)processSearchRequest:(ZMTransportRequest *)request;
{
    if (request.method == ZMMethodGET) {
        NSString *query = request.queryParameters[@"q"];
        NSUInteger limit = (NSUInteger) [request.queryParameters[@"l"] integerValue];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) AND (identifier != %@)", query, self.selfUser.identifier];
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequestWithPredicate:predicate];
        fetchRequest.fetchLimit = limit;
        
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        NSMutableArray *userPayload = [NSMutableArray array];
        for (MockUser *user in users) {
            
            MockConnection *connection = [self fetchConnectionFrom:self.selfUser to:user];
            
            NSMutableDictionary *payload = [(NSMutableDictionary *)user.transportData mutableCopy];
            
            payload[@"blocked"]= @NO;
            payload[@"connected"]= @(connection != nil);
            payload[@"level"]= @1;
            [payload removeObjectForKey:@"picture"];
            [payload removeObjectForKey:@"assets"];
            
            [userPayload addObject:payload];
        }
        
        NSDictionary *responsePayload = @{
                                          @"documents": userPayload
                                          };
        
        return [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}

// handles /onboarding
- (ZMTransportResponse *)processOnboardingRequest:(ZMTransportRequest *)request
{
    if(request.method == ZMMethodPOST) {
        NSArray *selfEmailArray = [[request.payload asDictionary] arrayForKey:@"self"];
        if(selfEmailArray.count == 0) {
            return [self errorResponseWithCode:400 reason:@"no self email" apiVersion:request.apiVersion];
        }
        NSArray *cards = [[request.payload asDictionary] arrayForKey:@"cards"];
        if(cards == nil) {
            return [self errorResponseWithCode:400 reason:@"missing contacts" apiVersion:request.apiVersion];
        }
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        // This method is just a simulation, it does not do any actual matching, it just returns all users
        NSMutableArray *results = [NSMutableArray array];
        for (MockUser *user in users) {
            if (user == self.selfUser) {
                continue;
            }
            [results addObject:@{
                                @"id" : user.identifier,
                                @"cards" : @[]
                                }];
        }
        return [ZMTransportResponse responseWithPayload:@{@"results" : results} HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
        
    }
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}


@end
