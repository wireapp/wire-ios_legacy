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

@interface ZMUpdateEventTests : ZMTBaseTest

@end

@interface ZMUpdateEventTests (Source)
@end
@interface ZMUpdateEventTests (Transient)
@end

@implementation ZMUpdateEventTests

- (NSDictionary *)typesMapping
{
    return @{
             @"conversation.asset-add" : @(ZMUpdateEventTypeConversationAssetAdd),
             @"conversation.connect-request" : @(ZMUpdateEventTypeConversationConnectRequest),
             @"conversation.create" : @(ZMUpdateEventTypeConversationCreate),
             @"conversation.delete" : @(ZMUpdateEventTypeConversationDelete),
             @"conversation.knock" : @(ZMUpdateEventTypeConversationKnock),
             @"conversation.member-join" : @(ZMUpdateEventTypeConversationMemberJoin),
             @"conversation.member-leave" : @(ZMUpdateEventTypeConversationMemberLeave),
             @"conversation.member-update" : @(ZMUpdateEventTypeConversationMemberUpdate),
             @"conversation.message-add" : @(ZMUpdateEventTypeConversationMessageAdd),
             @"conversation.client-message-add" : @(ZMUpdateEventTypeConversationClientMessageAdd),
             @"conversation.otr-message-add" : @(ZMUpdateEventTypeConversationOtrMessageAdd),
             @"conversation.otr-asset-add" : @(ZMUpdateEventTypeConversationOtrAssetAdd),
             @"conversation.rename" : @(ZMUpdateEventTypeConversationRename),
             @"conversation.typing" : @(ZMUpdateEventTypeConversationTyping),
             @"conversation.access-update" : @(ZMUpdateEventTypeConversationAccessModeUpdate),
             @"conversation.code-update" : @(ZMUpdateEventTypeConversationCodeUpdate),
             @"conversation.message-timer-update" : @(ZMUpdateEventTypeConversationMessageTimerUpdate),
             @"user.connection" : @(ZMUpdateEventTypeUserConnection),
             @"user.new" : @(ZMUpdateEventTypeUserNew),
             @"user.push-remove" : @(ZMUpdateEventTypeUserPushRemove),
             @"user.update" : @(ZMUpdateEventTypeUserUpdate),
             @"user.delete" : @(ZMUpdateEventTypeUserDelete),
             @"user.contact-join" : @(ZMUpdateEventTypeUserContactJoin),
             @"user.legalhold-enable": @(ZMUpdateEventTypeUserLegalHoldEnable),
             @"user.legalhold-disable": @(ZMUpdateEventTypeUserLegalHoldDisable),
             @"user.legalhold-request" : @(ZMUpdateEventTypeUserLegalHoldRequest),
             @"user.client-add" : @(ZMUpdateEventTypeUserClientAdd),
             @"user.client-remove" : @(ZMUpdateEventTypeUserClientRemove),
             @"team.create" : @(ZMUpdateEventTypeTeamCreate),
             @"team.delete" : @(ZMUpdateEventTypeTeamDelete),
             @"team.update" : @(ZMUpdateEventTypeTeamUpdate),
             @"team.member-join" : @(ZMUpdateEventTypeTeamMemberJoin),
             @"team.member-leave" : @(ZMUpdateEventTypeTeamMemberLeave),
             @"team.member-update" : @(ZMUpdateEventTypeTeamMemberUpdate),
             @"team.conversation-create" : @(ZMUpdateEventTypeTeamConversationCreate),
             @"team.conversation-delete" : @(ZMUpdateEventTypeTeamConversationDelete),
             @"feature-config.update" : @(ZMUpdateEventTypeFeatureConfigUpdate)
             };
}

- (void)testThatItParsesCorrectTypes
{
    // given

    NSDictionary *types = [self typesMapping];
    
    for (NSString *key in [types keyEnumerator]) {
        NSDictionary *data =
            @{
                @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
                @"payload" :
                    @[
                        @{
                        @"type" : key,
                        },
                    ]
            };

        NSArray *events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
        
        // when
        ZMUpdateEvent *event = events[0];

        // then
        XCTAssertNotNil(event);
        XCTAssertEqual([types[key] intValue], (int) event.type);
    }

}

- (void)testEventTypeConversion_1;
{
    // given
    NSArray *types = [self typesMapping].allKeys;
    
    // then
    for (NSString *s in types) {
        ZMUpdateEventType t = [ZMUpdateEvent updateEventTypeForEventTypeString:s];
        NSString *converted = [ZMUpdateEvent eventTypeStringForUpdateEventType:t];
        XCTAssertEqualObjects(converted, s);
    }
}

- (void)testEventTypeConversion_2;
{
    // given
    
    NSArray *types = [self typesMapping].allValues;
    
    // then
    for (NSNumber *n in types) {
        ZMUpdateEventType type = (ZMUpdateEventType) n.intValue;
        NSString *s = [ZMUpdateEvent eventTypeStringForUpdateEventType:type];
        ZMUpdateEventType converted = [ZMUpdateEvent updateEventTypeForEventTypeString:s];
        XCTAssertEqual(converted, type);
    }
}

- (void)testThatItReturnsNullForInvalidEventType
{
    // given
    NSString *eventType = @"myevent.invalid";
    id <ZMTransportData> data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[
                        @{
                            @"type" : eventType,
                        }
                        ]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];

    // then
    XCTAssertEqual(events.count, 0u);
}

- (void)testThatItReturnsNullForMissingEventType
{
    // given
    id <ZMTransportData> data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[@{}]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItReturnsNullForInvalidData
{
    // given
    id <ZMTransportData> data =
        @{
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItReturnsNullForNonDictionary
{
    // given
    id <ZMTransportData> data = @[];

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];
    
    // then
    XCTAssertEqual(events.count, 0u);

}

- (void)testThatItSetsPayload
{
    // given
    NSString *eventType = @"user.update";

    NSDictionary *innerPayload = @{
        @"type" : eventType,
        @"foo" : @"barzaz"
    };
    NSDictionary *data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[innerPayload]
        };

    // when
    __block NSArray *events;
    [self performIgnoringZMLogError:^{
        events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    }];

    // then
    XCTAssertEqual(events.count, 1u);
    ZMUpdateEvent *event = events[0];
    XCTAssertEqualObjects(event.payload, innerPayload);
}

- (void)testThatItSetsEventId
{
    // given
    NSString *eventType = @"user.update";

    NSDictionary *innerPayload = @{
        @"type" : eventType,
        @"foo" : @"barzaz"
    };
    NSDictionary *data =
        @{
            @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"payload" : @[innerPayload]
        };

    // when
    NSArray *events = [ZMUpdateEvent eventsArrayFromPushChannelData:data];
    
    // then
    XCTAssertEqual(events.count, 1u);
    ZMUpdateEvent *event = events[0];
    XCTAssertEqualObjects(event.uuid, [data[@"id"] UUID]);
}


- (void)testThatItSetsPayloadFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7c",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.payload, payload);
}

- (void)testThatItSetsPayloadFromStreamEventWithWrappedPayload
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7c",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };
    NSDictionary *wrappedPayload = @{ @"event" : payload };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:wrappedPayload uuid:nil];

    // then
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.payload, payload);
}

- (void)testThatItSetsIDToNilFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];

    // then
    XCTAssertNotNil(event);
    XCTAssertNil(event.uuid);
}

- (void)testThatItSetsTypeFromStreamEvent
{
    // given
    NSDictionary *payload = @{
        @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
        @"time" : @"2014-06-18T12:36:51.755Z",
        @"data" : @{
            @"content" : @"First! ;)",
            @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
        },
        @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
        @"id" : @"8.800122000a68ee1d",
        @"type" : @"conversation.message-add"
    };

    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];

    // then
    XCTAssertNotNil(event);
    XCTAssertEqual(ZMUpdateEventTypeConversationMessageAdd, event.type);
}




- (void)testThatItReturnsNullForInvalidEventTypeFromStreamEvent
{
    // given
    NSString *eventType = @"myevent.invalid";
    id <ZMTransportData> payload =
        @{
            @"type" : eventType,
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

- (void)testThatItReturnsNullForMissingEventTypeFromStreamEvent
{
    // given
    id <ZMTransportData> payload =
        @{
            @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
            @"time" : @"2014-06-18T12:36:51.755Z",
            @"data" : @{
                @"content" : @"First! ;)",
                @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
            },
            @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
            @"id" : @"8.800122000a68ee1d"
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}


- (void)testThatItReturnsNullForInvalidDataFromStreamEvent
{
    // given
    id <ZMTransportData> payload =
        @{
        };

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

- (void)testThatItReturnsNullForNonDictionaryFromStreamEvent
{
    // given
    id <ZMTransportData> payload = @[];

    // when
    __block ZMUpdateEvent *event;
    [self performIgnoringZMLogError:^{
        event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    }];

    // then
    XCTAssertNil(event);
}

@end


@implementation ZMUpdateEventTests (Source)

- (void)testThatItSetsTheSourceOnTheUpdateEvent
{
    [self performWithAllSourceTypes:^(ZMUpdateEventSource source) {
        // given & then
        NSArray <ZMUpdateEvent *>*events = [ZMUpdateEvent eventsArrayFromTransportData:self.pushChannelDataFixture source:source];
        XCTAssertEqual(events.firstObject.source, source);
    }];
}

- (void)testThatTheSourceForEventsFromPushChannelDataIsWebSocket
{
    // when
    NSArray <ZMUpdateEvent *>*events = [ZMUpdateEvent eventsArrayFromPushChannelData:self.pushChannelDataFixture];
    
    // then
    XCTAssertEqual(events.firstObject.source, ZMUpdateEventSourceWebSocket);
}

- (void)testThatItSetsTheSourceForEventsFromEventStreamPayloadIsDownload
{
    // when
    NSUUID *identifier = NSUUID.createUUID;
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:[self payloadFixtureWithID:identifier] uuid:identifier];
    
    // then
    XCTAssertEqual(event.source, ZMUpdateEventSourceDownload);
}

- (void)testThatItSetsTheSourceWhenCreatingDecryptedUpdateEventFromTransportData
{
    [self performWithAllSourceTypes:^(ZMUpdateEventSource source) {
        NSUUID *identifier = NSUUID.createUUID;
        ZMUpdateEvent *event = [ZMUpdateEvent decryptedUpdateEventFromEventStreamPayload:[self payloadFixtureWithID:identifier] uuid:identifier transient:NO source:source];
        XCTAssertEqual(event.source, source);
    }];
}

- (void)performWithAllSourceTypes:(void (^)(ZMUpdateEventSource))block
{
    ZMUpdateEventSource sources[3] = { ZMUpdateEventSourceDownload, ZMUpdateEventSourcePushNotification, ZMUpdateEventSourceWebSocket };
    NSUInteger size = sizeof(sources) / sizeof(ZMUpdateEventSource);
    for (NSUInteger idx = 0; idx < size; idx++) {
        block(sources[idx]);
    }
}

- (void)testThatItDoesNotSetAnySourcesToPushWhenTheThresholdUUIDIsSetToNil
{
    // when
    NSArray <ZMUpdateEvent *> *events = [ZMUpdateEvent eventsArrayFromPushChannelData:self.pushChannelDataFixture pushStartingAt:nil];

    // then
    XCTAssertEqual(events.count, 1lu);

    for (ZMUpdateEvent *event in events) {
        XCTAssertEqual(event.source, ZMUpdateEventSourceWebSocket);
    }
}

- (void)testThatItSetsTheSourceToPushForUUIDsEqualOrGreaterThanTheThresholdUUID
{
    // Given
    NSUUID *threshold = [NSUUID uuidWithTransportString:@"864FA306-99D1-11E6-Bfff-22000A79A0F0"];
    NSUUID *older = [NSUUID uuidWithTransportString:@"6f83DAd4-99D1-11E6-BFFF-22000A79A0f0"];
    NSUUID *newer = [NSUUID uuidWithTransportString:@"937DC35A-99D1-11E6-BFFF-22000A79A0F0"];

    XCTAssertEqual([threshold compareWithType1UUID:older], NSOrderedDescending);
    XCTAssertEqual([threshold compareWithType1UUID:newer], NSOrderedAscending);

    NSArray <NSUUID *> *identifiers = @[older, threshold, newer];
    for (NSUUID *identifier in identifiers) {
        XCTAssertTrue(identifier.isType1UUID);
    }

    // When
    NSArray <ZMUpdateEvent *> *oldestEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:[self pushChannelDataFixtureWithId:older] pushStartingAt:threshold];
    NSArray <ZMUpdateEvent *> *currentEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:[self pushChannelDataFixtureWithId:threshold] pushStartingAt:threshold];
    NSArray <ZMUpdateEvent *> *newerEvents = [ZMUpdateEvent eventsArrayFromPushChannelData:[self pushChannelDataFixtureWithId:newer] pushStartingAt:threshold];

    // Then
    XCTAssertNotNil(oldestEvents);
    XCTAssertNotNil(currentEvents);
    XCTAssertNotNil(newerEvents);

    XCTAssertEqual(oldestEvents.count, 1lu);
    XCTAssertEqual(currentEvents.count, 1lu);
    XCTAssertEqual(newerEvents.count, 1lu);

    XCTAssertEqual(oldestEvents.firstObject.source, ZMUpdateEventSourceWebSocket);
    XCTAssertEqual(currentEvents.firstObject.source, ZMUpdateEventSourcePushNotification);
    XCTAssertEqual(newerEvents.firstObject.source, ZMUpdateEventSourcePushNotification);
}

#pragma mark - Helper

- (id <ZMTransportData>)payloadFixture
{
    return [self payloadFixtureWithID:nil];
}

- (id <ZMTransportData>)payloadFixtureWithID:(NSUUID *)identifier
{
    return @{
             @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7c",
             @"time" : @"2014-06-18T12:36:51.755Z",
             @"data" : @{
                     @"content" : @"Foo Bar Bazinga",
                     @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
                     },
             @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
             @"id" : identifier.transportString ?: @"8.800122000a68ee1d",
             @"type" : @"conversation.message-add"
             };
}

- (id <ZMTransportData>)pushChannelDataFixture
{
    return [self pushChannelDataFixtureWithId:nil];
}

- (id <ZMTransportData>)pushChannelDataFixtureWithId:(NSUUID *)identifier
{
    return @{
             @"id" : identifier.transportString ?: @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
             @"payload" : @[
                     @{
                         @"type" : @"user.update",
                         @"foo" : @"barzaz"
                         }
                     ]
             };
}

@end


@implementation ZMUpdateEventTests (Transient)

- (void)testThatAnEventIsNotTransientIfNotSpecified_Stream
{
    // given
    NSDictionary *payload = @{
                              @"conversation" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
                              @"time" : @"2014-06-18T12:36:51.755Z",
                              @"data" : @{
                                      @"content" : @"First! ;)",
                                      @"nonce" : @"a80a81e3-9ff1-ac27-03ee-06bbc6d7b5cb"
                                      },
                              @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                              @"id" : @"8.800122000a68ee1d",
                              @"type" : @"conversation.message-add"
                              };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // then
    XCTAssertFalse(event.isTransient);
}

- (void)testThatAnEventIsNotTransientIfNotSpecified_Push
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"payload" : @[
                      @{
                          @"type" : @"user.update",
                          @"foo" : @"barzaz"
                      }
                    ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertFalse(event.isTransient);
}

- (void)testThatAnEventIsNotTransientIfExplicitlySaysSo
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"transient" : @(NO),
      @"payload" : @[
              @{
                  @"type" : @"user.update",
                  @"foo" : @"barzaz"
                  }
              ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertFalse(event.isTransient);
}


- (void)testThatAnEventIsTransientIfExplicitlySaysSo
{
    // given
    NSDictionary *data =
    @{
      @"id" : @"0d30d26f-3b5e-4b7b-8f9a-efa2e5f9ca7a",
      @"transient" : @(YES),
      @"payload" : @[
              @{
                  @"type" : @"user.update",
                  @"foo" : @"barzaz"
                  }
              ]
      };
    
    // when
    ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:data].firstObject;
    
    // then
    XCTAssertTrue(event.isTransient);
}

@end
