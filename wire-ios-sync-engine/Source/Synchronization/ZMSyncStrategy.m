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


@import UIKit;
@import WireImages;
@import WireUtilities;
@import WireTransport;
@import WireDataModel;
@import WireRequestStrategy;

#import "ZMSyncStrategy+Internal.h"
#import "ZMSyncStrategy+ManagedObjectChanges.h"
#import "WireSyncEngineLogs.h"
#import "ZMClientRegistrationStatus.h"
#import "ZMHotFix.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

@interface ZMSyncStrategy ()

@property (nonatomic) BOOL didFetchObjects;
@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic, weak) NSManagedObjectContext *uiMOC;

@property (nonatomic) id<ZMApplication> application;

@property (nonatomic) ZMChangeTrackerBootstrap *changeTrackerBootStrap;
@property (nonatomic) id<StrategyDirectoryProtocol> strategyDirectory;

@property (nonatomic, weak) ApplicationStatusDirectory *applicationStatusDirectory;

@property (atomic) BOOL tornDown;
@property (nonatomic) BOOL contextMergingDisabled;

@property (nonatomic) NotificationDispatcher *notificationDispatcher;

@end


@interface ZMSyncStrategy (Registration) <ZMClientRegistrationStatusDelegate>
@end

@interface ZMClientRegistrationStatus (Protocol) <ClientRegistrationDelegate>
@end


@implementation ZMSyncStrategy

ZM_EMPTY_ASSERTING_INIT()


- (instancetype)initWithContextProvider:(id<ContextProvider>)contextProvider
                notificationsDispatcher:(NotificationDispatcher *)notificationsDispatcher
             applicationStatusDirectory:(ApplicationStatusDirectory *)applicationStatusDirectory
                            application:(id<ZMApplication>)application
                      strategyDirectory:(id<StrategyDirectoryProtocol>)strategyDirectory
                 eventProcessingTracker:(id<EventProcessingTrackerProtocol>)eventProcessingTracker
{
    self = [super init];
    if (self) {
        self.notificationDispatcher = notificationsDispatcher;
        self.application = application;
        self.syncMOC = contextProvider.syncContext;
        self.uiMOC = contextProvider.viewContext;
        self.applicationStatusDirectory = applicationStatusDirectory;
        self.strategyDirectory = strategyDirectory;
        self.eventProcessingTracker = eventProcessingTracker;
        self.changeTrackerBootStrap = [[ZMChangeTrackerBootstrap alloc] initWithManagedObjectContext:self.syncMOC changeTrackers:self.strategyDirectory.contextChangeTrackers];

        ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.syncMOC]);
        ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:contextProvider.viewContext]);

        [application registerObserverForDidEnterBackground:self selector:@selector(appDidEnterBackground:)];
        [application registerObserverForWillEnterForeground:self selector:@selector(appWillEnterForeground:)];
        [application registerObserverForApplicationWillTerminate:self selector:@selector(appTerminated:)];
    }
    return self;
}

- (void)appDidEnterBackground:(NSNotification *)note
{
    NOT_USED(note);
    BackgroundActivity *activity = [BackgroundActivityFactory.sharedFactory startBackgroundActivityWithName:@"enter background"];
    [self.notificationDispatcher applicationDidEnterBackground];
    [self.syncMOC performGroupedBlock:^{
        self.applicationStatusDirectory.operationStatus.isInBackground = YES;
        [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];

        if (activity) {
            [BackgroundActivityFactory.sharedFactory endBackgroundActivity:activity];
        }
    }];
}

- (void)appWillEnterForeground:(NSNotification *)note
{
    NOT_USED(note);
    BackgroundActivity *activity = [BackgroundActivityFactory.sharedFactory startBackgroundActivityWithName:@"enter foreground"];
    [self.notificationDispatcher applicationWillEnterForeground];
    [self.syncMOC performGroupedBlock:^{
        self.applicationStatusDirectory.operationStatus.isInBackground = NO;
        [ZMRequestAvailableNotification notifyNewRequestsAvailable:self];

        if (activity) {
            [BackgroundActivityFactory.sharedFactory endBackgroundActivity:activity];
        }
    }];
}

- (void)appTerminated:(NSNotification *)note
{
    NOT_USED(note);
    [self.application unregisterObserverForStateChange:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSManagedObjectContext *)moc
{
    return self.syncMOC;
}

- (void)tearDown
{
    self.tornDown = YES;
    self.applicationStatusDirectory = nil;
    self.changeTrackerBootStrap = nil;
    self.strategyDirectory = nil;
    [self appTerminated:nil];
    [self.notificationDispatcher tearDown];
}

#if DEBUG
- (void)dealloc
{
    RequireString(self.tornDown, "Did not tear down %p", (__bridge void *) self);
}
#endif

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion
{
    if (!self.didFetchObjects) {
        self.didFetchObjects = YES;
        [self.changeTrackerBootStrap fetchObjectsForChangeTrackers];
    }

    if(self.tornDown) {
        return nil;
    }

    for (id<RequestStrategy> requestStrategy in self.strategyDirectory.requestStrategies) {
        ZMTransportRequest *request = [requestStrategy nextRequestForAPIVersion:apiVersion];

        if (request != nil) {
            return request;
        }
    }

    return nil;
}

@end
