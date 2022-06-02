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


#import "ZMOTRMessage.h"
#import "ZMConversation+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>


@import WireTransport;


NSString * const DeliveredKey = @"delivered";


@implementation ZMOTRMessage

@dynamic buttonStates;
@dynamic dataSet;
@dynamic missingRecipients;

- (NSString *)entityName;
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (NSSet *)ignoredKeys;
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[DeliveredKey, ZMMessageIsExpiredKey]];
}

- (void)missesRecipient:(UserClient *)recipient
{
    [self missesRecipients:[NSSet setWithObject:recipient]];
}

- (void)missesRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] addObjectsFromArray:recipients.allObjects];
}

- (void)doesNotMissRecipient:(UserClient *)recipient
{
    [self doesNotMissRecipients:[NSSet setWithObject:recipient]];
}

- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] minusSet:recipients];
}

- (ZMDeliveryState)deliveryState
{
    //we set server time stamp in awake from insert to be able to sort messages
    //probably we need to store "deliveryTimestamp" separately and check it here
    if (self.isExpired) {
        return ZMDeliveryStateFailedToSend;
    }
    else if (self.delivered == NO) {
        return ZMDeliveryStatePending;
    }
    else if (self.readReceipts.count > 0) {
        return ZMDeliveryStateRead;
    }
    else if (self.confirmations.count > 0){
        return ZMDeliveryStateDelivered;
    }
    else {
        return ZMDeliveryStateSent;
    }
}

- (BOOL)isSent
{
    return self.delivered;
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [[ZMMessage keyPathsForValuesAffectingValueForKey:ZMMessageDeliveryStateKey] setByAddingObject:DeliveredKey];
}

- (void)markAsSent
{
    self.delivered = YES;
    [super markAsSent];
}

- (void)expire
{
    [super expire];
}

- (void)resend
{
    self.delivered = NO;
    [super resend];
}

- (BOOL)isUpdatingExistingMessage
{
    return NO;
}

- (void)updateWithUpdateEvent:(__unused ZMUpdateEvent *)updateEvent initialUpdate:(__unused BOOL)initialUpdate {
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    // `createOrUpdateMessageFromUpdateEvent..` is originally declared in `ZMMessage`
    // We must override the original implementation in `ZMOTRMessage`
    // We cannot do the override in the Swift extension of `ZMOTRMessage`
    // (Extensions can add new functionality to a type, but they cannot override existing functionality)
    // So, for now we call the Swift implementation of this method.
    // When converting ZMOTRMessage to Swift, we can move the code of the extension method to the Swift override
    return [ZMOTRMessage createOrUpdateFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:prefetchResult];
}

-(void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(NSSet *)updatedKeys {

    NSDate *timestamp = [payload dateFor:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else if( ! [timestamp isEqualToDate:self.serverTimestamp]) {
        self.expectsReadConfirmation = self.conversation.hasReadReceiptsEnabled;
    }
    
    [super updateWithPostPayload:payload updatedKeys:updatedKeys];
}

@end
