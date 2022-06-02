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

#import "MockTransportSession+notifications.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockTransportSession (Notifications)

// handles /push/fallback
- (ZMTransportResponse *)processNotificationFallbackRequest:(ZMTransportRequest *)request
{
    if([request matchesWithPath:@"/push/fallback" method:ZMMethodPOST]) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}


/// handles /notifications
- (ZMTransportResponse *)processNotificationsRequest:(ZMTransportRequest *)request
{
    // /notifications
    if ([request matchesWithPath:@"/notifications" method:ZMMethodGET]) {
        
        NSUUID *since = [request.queryParameters optionalUuidForKey:@"since"];
        
        NSArray *eventsToSend;
        BOOL notFound = NO;
        if(since != nil) {
            NSUInteger index = [self.generatedPushEvents indexOfObjectPassingTest:^BOOL(MockPushEvent *obj, NSUInteger idx, BOOL *stop) {
                NOT_USED(idx);
                NOT_USED(stop);
                return [obj.uuid isEqual:since];
            }];
            notFound = index == NSNotFound;
            if(!notFound) {
                ++index;
                eventsToSend = [self.generatedPushEvents subarrayWithRange:NSMakeRange(index, self.generatedPushEvents.count - index)];
            }
        }
        if (eventsToSend == nil) {
            eventsToSend = self.generatedPushEvents;
        }
        
        NSArray *payload = [eventsToSend mapWithBlock:^id(MockPushEvent *event) {
            return event.transportData;
        }];
        NSInteger statusCode = notFound ? 404 : 200;
        return [ZMTransportResponse responseWithPayload:@{@"notifications":payload} HTTPStatus:statusCode transportSessionError:nil apiVersion:request.apiVersion];
    }
    // /notifications/last
    else if([request matchesWithPath:@"/notifications/last" method:ZMMethodGET])
    {
        MockPushEvent *last = self.generatedPushEvents.lastObject;
        if(last != nil) {
            return [ZMTransportResponse responseWithPayload:last.transportData HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
        }
        else {
            return [self errorResponseWithCode:404 reason:@"no notification to send" apiVersion:request.apiVersion];
        }
    }
    else {
        return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
    }
}

@end
