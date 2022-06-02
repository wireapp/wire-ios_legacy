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
@import WireUtilities;
@import CoreData;
#import "MockTransportSession+internal.h"
#import "MockTransportSession.h"
#import <WireMockTransport/WireMockTransport-Swift.h>
#import "MockConnection.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockTransportSession (ConnectionsHelper)



/// handles /connections
- (ZMTransportResponse *)processSelfConnectionsRequest:(ZMTransportRequest *)sessionRequest;
{
    if ([sessionRequest matchesWithPath:@"/connections" method:ZMMethodGET]) {
        return [self processGetConnections:sessionRequest.queryParameters apiVersion:sessionRequest.apiVersion];
    }
    if ([sessionRequest matchesWithPath:@"/connections/*" method:ZMMethodGET]) {
        return [self processGetSpecifiedConnection:sessionRequest];
    }
    if ([sessionRequest matchesWithPath:@"/connections" method:ZMMethodPOST]) {
        return [self processPostConnection:sessionRequest];
    }
    if ([sessionRequest matchesWithPath:@"/connections/*" method:ZMMethodPUT]) {
        return [self processPutConnection:sessionRequest];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
}


/// PUT /connections/<to-user-id>
- (ZMTransportResponse *)processPutConnection:(ZMTransportRequest *)sessionRequest
{
    NSString *remoteID = [sessionRequest RESTComponentAtIndex:1];
    MockConnection *connection = [self connectionFromUserIdentifier:self.selfUser.identifier toUserIdentifier:remoteID];
    if (connection == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
    }
    
    NSDictionary *changedFields = [sessionRequest.payload asDictionary];
    if (changedFields == nil) {
        return [self errorResponseWithCode:400 reason:@"missing fields" apiVersion:sessionRequest.apiVersion];
    }
    
    for (NSString *key in changedFields.allKeys) {
        if([key isEqualToString:@"status"]) {
            ZMTConnectionStatus oldStatus = [MockConnection statusFromString:connection.status];
            connection.status = changedFields[key];
            ZMTConnectionStatus status = [MockConnection statusFromString:connection.status];
            
            if (status == ZMTConnectionStatusSent && oldStatus == ZMTConnectionStatusCancelled) {
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:403 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
            }
            
            switch (status) {
                case ZMTConnectionStatusPending:
                case ZMTConnectionStatusIgnored:
                case ZMTConnectionStatusSent:
                    connection.conversation.type = ZMTConversationTypeConnection;
                    break;
                    
                case ZMTConnectionStatusAccepted:
                case ZMTConnectionStatusBlocked:
                    connection.conversation.type = ZMTConversationTypeOneOnOne;
                    break;
                    
                default:
                    connection.conversation.type = ZMTConversationTypeInvalid;
                    break;	
            }
        }
    }
    
    connection.lastUpdate = [NSDate date];
    
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:200 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
}


/// GET /connections/<to-user-id>
- (ZMTransportResponse *)processGetSpecifiedConnection:(ZMTransportRequest *)sessionRequest
{
    NSString *remoteID = [sessionRequest RESTComponentAtIndex:1];
    MockConnection *connection = [self connectionFromUserIdentifier:self.selfUser.identifier toUserIdentifier:remoteID];
    if (connection == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
    }
    
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:200 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
}

/// GET /connections
- (ZMTransportResponse *)processGetConnections:(NSDictionary *)queryParameters apiVersion:(APIVersion)apiVersion
{
    NSString *sizeString = [queryParameters optionalStringForKey:@"size"];
    NSUUID *start = [queryParameters optionalUuidForKey:@"start"];
    
    NSFetchRequest *request = [MockConnection sortedFetchRequest];
    
    NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    if(start != nil) {
        NSUInteger index = [connections indexOfObjectPassingTest:^BOOL(MockConnection *obj, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            if([obj.to.identifier isEqualToString:start.transportString]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if(index != NSNotFound) {
            connections = [connections subarrayWithRange:NSMakeRange(index+1, connections.count - index-1)];
        }
    }
    
    BOOL hasMore = NO;
    if(sizeString != nil) {
        NSUInteger remainingConnections = connections.count;
        NSUInteger connectionsToFetch = (NSUInteger) sizeString.integerValue;
        hasMore = (remainingConnections > connectionsToFetch);
        NSUInteger connectionsToReturn = MIN(remainingConnections, connectionsToFetch);
        connections = [connections subarrayWithRange:NSMakeRange(0u, connectionsToReturn)];
    }

    NSMutableDictionary *resultData = [NSMutableDictionary dictionary];
    resultData[@"has_more"] = @(hasMore);
    NSMutableArray *connectionData = [NSMutableArray array];
    for (MockConnection *c in connections) {
        [connectionData addObject:c.transportData];
    }
    resultData[@"connections"] = connectionData;
    
    return [ZMTransportResponse responseWithPayload:resultData HTTPStatus:200 transportSessionError:nil apiVersion:apiVersion];
}

/// POST /connections
- (ZMTransportResponse *)processPostConnection:(ZMTransportRequest *)sessionRequest
{
    NSString *userID = [[sessionRequest.payload asDictionary] stringForKey:@"user"];
    NSString *message = [[sessionRequest.payload asDictionary] optionalStringForKey:@"message"];
    
    MockUser *user = [self fetchUserWithIdentifier:userID];
    MockConnection *connection = [self createConnectionRequestFromUser:self.selfUser toUser:user message:message];
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:201 transportSessionError:nil apiVersion:sessionRequest.apiVersion];
}

@end
