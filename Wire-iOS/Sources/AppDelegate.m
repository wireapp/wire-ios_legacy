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


#import "AppDelegate.h"

#import "WireSyncEngine+iOS.h"
#import "Wire-Swift.h"

// Helpers

#import "AppDelegate+Hockey.h"
#import "Application+runDuration.h"
#import "ZClientViewController.h"
#import "Analytics.h"
#import "AnalyticsTracker+Registration.h"
#import "AnalyticsTracker+Permissions.h"

// Performance Measurement
#import "StopWatch.h"


NSString *const ZMUserSessionDidBecomeAvailableNotification = @"ZMUserSessionDidBecomeAvailableNotification";

static NSString* ZMLogTag ZM_UNUSED = @"UI";
static AppDelegate *sharedAppDelegate = nil;


@interface AppDelegate ()

@property (nonatomic) AppRootViewController *rootViewController;
@property (nonatomic, assign) BOOL trackedResumeEvent;
@property (nonatomic, assign, readwrite) ApplicationLaunchType launchType;
@property (nonatomic, copy) NSDictionary *launchOptions;

@end


@interface AppDelegate (PushNotifications)
@end


@implementation AppDelegate

+ (instancetype)sharedAppDelegate;
{
    return sharedAppDelegate;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        sharedAppDelegate = self;
    }
    return self;
}

- (void)setupBackendEnvironment
{
    NSString *BackendEnvironmentTypeKey = @"ZMBackendEnvironmentType";
    NSString *backendEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:BackendEnvironmentTypeKey];
    [[NSUserDefaults sharedUserDefaults] setObject:backendEnvironment forKey:BackendEnvironmentTypeKey];
    
    if (backendEnvironment.length == 0 || [backendEnvironment isEqualToString:@"default"]) {
        NSString *defaultBackend = @STRINGIZE(DEFAULT_BACKEND);
        
        ZMLogInfo(@"Backend environment is <not defined>. Using '%@'.", defaultBackend);
        [[NSUserDefaults standardUserDefaults] setObject:defaultBackend forKey:BackendEnvironmentTypeKey];
        [[NSUserDefaults sharedUserDefaults] setObject:defaultBackend forKey:BackendEnvironmentTypeKey];
    } else {
        ZMLogInfo(@"Using '%@' backend environment", backendEnvironment);
    }
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ZMLogInfo(@"application:willFinishLaunchingWithOptions %@ (applicationState = %ld)", launchOptions, (long)application.applicationState);
    
    // Initial log line to indicate the client version and build
    ZMLogInfo(@"Wire-ios version %@ (%@)",
              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
              [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *) kCFBundleVersionKey]);
    
    // Note: if we instantiate the root view controller (& windows) any earlier,
    // the windows will not receive any info about device orientation.
    self.rootViewController = [[AppRootViewController alloc] init];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ZMSLog switchCurrentLogToPrevious];
    
    ZMLogInfo(@"application:didFinishLaunchingWithOptions START %@ (applicationState = %ld)", launchOptions, (long)application.applicationState);
    
    [self setupBackendEnvironment];

    [self setupTracking];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSessionDidBecomeAvailable:)
                                                 name:ZMUserSessionDidBecomeAvailableNotification
                                               object:nil];
    
    [self setupHockeyWithCompletion:^() {
        [self.rootViewController launchWith:launchOptions];
    }];
    self.launchOptions = launchOptions;
    
    ZMLogInfo(@"application:didFinishLaunchingWithOptions END %@", launchOptions);
    ZMLogInfo(@"Application was launched with arguments: %@",[[NSProcessInfo processInfo]arguments]);

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    ZMLogInfo(@"applicationWillEnterForeground: (applicationState = %ld)", (long)application.applicationState);
}

- (void)applicationDidBecomeActive:(UIApplication *)application;
{
    ZMLogInfo(@"applicationDidBecomeActive START (applicationState = %ld)", (long)application.applicationState);
    
    switch (self.launchType) {
        case ApplicationLaunchURL:
        case ApplicationLaunchPush:
            break;
        default:
            self.launchType = ApplicationLaunchDirect;
            break;
    }
    
    if (! self.trackedResumeEvent) {
        [[Analytics shared] tagAppLaunchWithType:self.launchType];
    }
    
    self.trackedResumeEvent = NO;
    
    ZMLogInfo(@"applicationDidBecomeActive END");
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    ZMLogInfo(@"applicationWillResignActive:  (applicationState = %ld)", (long)application.applicationState);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    ZMLogInfo(@"applicationDidEnterBackground:  (applicationState = %ld)", (long)application.applicationState);
    
    self.launchType = ApplicationLaunchUnknown;
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [self.sessionManager.urlHandler openURL:url options:options];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    ZMLogInfo(@"applicationWillTerminate:  (applicationState = %ld)", (long)application.applicationState);
    
    // In case of normal termination we do not need the run duration to persist
    [[UIApplication sharedApplication] resetRunDuration];
}

- (void)application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void (^)(BOOL))completionHandler
{
    [self.rootViewController.quickActionsManager performActionFor:shortcutItem
                                                completionHandler:completionHandler];
}

- (void)setupTracking
{
    BOOL containsConsoleAnalytics = [[[NSProcessInfo processInfo] arguments] indexOfObjectPassingTest:^BOOL(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:AnalyticsProviderFactory.ZMConsoleAnalyticsArgumentKey]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] != NSNotFound;
    
    [AnalyticsProviderFactory shared].useConsoleAnalytics = containsConsoleAnalytics;
    [Analytics loadSharedWithOptedOut:[[TrackingManager shared] disableCrashAndAnalyticsSharing]];
}

- (void)trackLaunchAnalyticsWithLaunchOptions:(NSDictionary *)launchOptions
{
    self.launchType = ApplicationLaunchDirect;
    if (launchOptions[UIApplicationLaunchOptionsURLKey] != nil) {
        self.launchType = ApplicationLaunchURL;
    }
    
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] != nil ||
        launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] != nil) {
        self.launchType = ApplicationLaunchPush;
    }
    [[UIApplication sharedApplication] setupRunDurationCalculation];
    [[Analytics shared] tagAppLaunchWithType:self.launchType];
    self.trackedResumeEvent = YES;
}

- (void)userSessionDidBecomeAvailable:(NSNotification *)notification
{
    [self trackLaunchAnalyticsWithLaunchOptions:self.launchOptions];
    [self trackErrors];
}

#pragma mark - URL handling

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    ZMLogInfo(@"application:continueUserActivity:restorationHandler: %@", userActivity);
    return [[SessionManager shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
}

#pragma mark - AppController

- (UnauthenticatedSession *)unauthenticatedSession
{
    return [[SessionManager shared] unauthenticatedSession];
}

- (CallWindowRootViewController *)callWindowRootViewController
{
    return (CallWindowRootViewController *)self.rootViewController.callWindow.rootViewController;
}

- (SessionManager *)sessionManager
{
    return self.rootViewController.sessionManager;
}

- (UIWindow *)window
{
    return self.rootViewController.mainWindow;
}

- (void)setWindow:(UIWindow *)window
{
    NSAssert(1, @"cannot set window");
}

- (UIWindow *)notificationsWindow
{
    return self.rootViewController.overlayWindow;
}

- (MediaPlaybackManager *)mediaPlaybackManager
{
    if ([self.rootViewController.visibleViewController isKindOfClass:ZClientViewController.class]) {
        ZClientViewController *clientViewController = (ZClientViewController *)self.rootViewController.visibleViewController;
        return clientViewController.mediaPlaybackManager;
    }
    
    return nil;
}

@end



@implementation AppDelegate (PushNotifications)

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    BOOL userGavePermissions = (notificationSettings.types != UIUserNotificationTypeNone);
    AnalyticsTracker *analyticsTracker = [AnalyticsTracker analyticsTrackerWithContext:nil];
    [analyticsTracker tagPushNotificationsPermissions:userGavePermissions];
}

@end

@implementation AppDelegate (BackgroundUpdates)

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    ZMLogInfo(@"application:didReceiveRemoteNotification:fetchCompletionHandler: notification: %@", userInfo);
    if (application.applicationState == UIApplicationStateActive) {
        [[Analytics shared] tagAppLaunchWithType:ApplicationLaunchPush];
        self.trackedResumeEvent = YES;
    }
    
    self.launchType = (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) ? ApplicationLaunchPush: ApplicationLaunchDirect;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    ZMLogInfo(@"application:didReceiveLocalNotification: %@", notification);
    
    [[SessionManager shared] didReceiveLocalNotification:notification application:application];
    
    self.launchType = (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) ? ApplicationLaunchPush: ApplicationLaunchDirect;
}

- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification
  completionHandler:(void (^)(void))completionHandler
{
    ZMLogInfo(@"application:handleActionWithIdentifier:forLocalNotification: identifier: %@, notification: %@", identifier, notification);
    
    [[SessionManager shared] handleActionWithIdentifier:identifier
                                   forLocalNotification:notification
                                       withResponseInfo:[NSDictionary dictionary]
                                      completionHandler:completionHandler
                                            application:application];
}

- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification
   withResponseInfo:(NSDictionary *)responseInfo
  completionHandler:(void(^)(void))completionHandler;
{
    ZMLogInfo(@"application:handleActionWithIdentifier:forLocalNotification: identifier: %@, notification: %@ responseInfo: %@", identifier, notification, responseInfo);
    
    [[SessionManager shared] handleActionWithIdentifier:identifier
                                   forLocalNotification:notification
                                       withResponseInfo:responseInfo
                                      completionHandler:completionHandler
                                            application:application];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;
{
    ZMLogInfo(@"application:performFetchWithCompletionHandler:");
    
    [self.rootViewController performWhenAuthenticated:^{
        [[ZMUserSession sharedSession] application:application performFetchWithCompletionHandler:completionHandler];
    }];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
{
    ZMLogInfo(@"application:handleEventsForBackgroundURLSession:completionHandler: session identifier: %@", identifier);
    
    [self.rootViewController performWhenAuthenticated:^{
        [[ZMUserSession sharedSession] application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    }];
}

@end
