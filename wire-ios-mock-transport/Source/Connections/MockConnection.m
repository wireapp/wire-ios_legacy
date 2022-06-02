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
#import "MockConnection.h"
#import "MockConversation.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockConnection

@dynamic status;
@dynamic conversation;
@dynamic to;
@dynamic from;
@dynamic lastUpdate;
@dynamic message;

- (id<ZMTransportData>)transportData;
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"status"] = self.status ?: [NSNull null];
    data[@"conversation"] = self.conversation ? self.conversation.identifier : [NSNull null];
    data[@"to"] = self.to ? self.to.identifier : [NSNull null];
    data[@"from"] = self.from ? self.from.identifier : [NSNull null];
    data[@"last_update"] = [self.lastUpdate transportString] ?: [NSNull null];
    data[@"message"] = self.message ?: [NSNull null];
    return data;
}

- (void)accept
{
    self.status = @"accepted";
    self.lastUpdate = [NSDate date];
    RequireString(self.conversation != nil, "No conversation");
    NSArray *addedUsers = @[self.to];
    [self.conversation addUsersByUser:self.from addedUsers:addedUsers];
    self.conversation.type = ZMTConversationTypeOneOnOne;
}

+ (NSFetchRequest *)sortedFetchRequest;
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Connection"];
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"lastUpdate" ascending:YES];
    request.sortDescriptors = @[sd];
    return request;
}


+ (MockConnection *)connectionInMOC:(NSManagedObjectContext *)moc from:(MockUser *)from to:(MockUser *)to message:(NSString *)message;
{
    MockConnection *connection = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Connection" inManagedObjectContext:moc];
    connection.from = from;
    connection.to = to;
    connection.message = message;
    connection.lastUpdate = [NSDate date];
    connection.status = @"sent";
    
    return connection;
    
}

+ (NSArray *)connectionStringToEnumValueTuples
{
    static NSArray *mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping =
        @[
          @[@(ZMTConnectionStatusAccepted), @"accepted"],
          @[@(ZMTConnectionStatusBlocked), @"blocked"],
          @[@(ZMTConnectionStatusCancelled), @"cancelled"],
          @[@(ZMTConnectionStatusIgnored),@"ignored"],
          @[@(ZMTConnectionStatusPending),@"pending"],
          @[@(ZMTConnectionStatusSent),@"sent"]
        ];
    });
    return mapping;
}

+ (NSString *)stringFromStatus:(ZMTConnectionStatus)status
{
    for(NSArray *tuple in [MockConnection connectionStringToEnumValueTuples]) {
        if([tuple[0] isEqualToNumber:@(status)]) {
            return tuple[1];
        }
    }
    RequireString(false, "Failed to parse ZMTConnectionStatus %hd", status);
}

+ (ZMTConnectionStatus)statusFromString:(NSString *)string
{
    for(NSArray *tuple in [MockConnection connectionStringToEnumValueTuples]) {
        if([tuple[1] isEqualToString:string]) {
            return (ZMTConnectionStatus) ((NSNumber *)tuple[0]).intValue;
        }
    }
    RequireString(false, "Failed to parse ZMTConnectionStatus %s", string.UTF8String);
}

@end
