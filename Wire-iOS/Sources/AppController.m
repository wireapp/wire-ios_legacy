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


#import "AppController.h"
#import "AppController+Internal.h"

#import "zmessaging+iOS.h"
#import "ZMUserSession+Additions.h"
#import "MagicConfig.h"
#import "PassthroughWindow.h"

#import "LaunchImageViewController.h"
#import "NotificationWindowRootViewController.h"

@import CocoaLumberjack;
@import Classy;
@import WireExtensionComponents;
@import CallKit;
#import <avs/AVSFlowManager.h>
#import "avs+iOS.h"
#import "MediaPlaybackManager.h"
#import "StopWatch.h"
#import "Settings.h"
#import "UIColor+WAZExtensions.h"
#import "ColorScheme.h"
#import "CASStyler+Variables.h"
#import "Analytics+iOS.h"
#import "Analytics+Performance.h"
#import "AVSLogObserver.h"
#import "Wire-Swift.h"

NSString *const ZMUserSessionDidBecomeAvailableNotification = @"ZMUserSessionDidBecomeAvailableNotification";

@interface AppController ()
@property (nonatomic) AppUIState uiState;
@property (nonatomic) AppSEState seState;
@property (nonatomic) ZMUserSessionErrorCode signInErrorCode;
@property (nonatomic) BOOL enteringForeground;

@property (nonatomic) id<ZMAuthenticationObserverToken> authToken;
@property (nonatomic) ZMUserSession *zetaUserSession;
@property (nonatomic) NotificationWindowRootViewController *notificationWindowController;
@property (nonatomic, weak) LaunchImageViewController *launchImageViewController;
@property (nonatomic) UIWindow *notificationsWindow;
@property (nonatomic) MediaPlaybackManager *mediaPlaybackManager;
@property (nonatomic) SessionObjectCache *sessionObjectCache;
@property (nonatomic) AVSLogObserver *logObserver;
@property (nonatomic) NSString *groupIdentifier;

@property (nonatomic) NSMutableArray <dispatch_block_t> *blocksToExecute;

@property (nonatomic) ClassyCache *classyCache;

@end



@interface AppController (AuthObserver) <ZMAuthenticationObserver>
@end

@interface AppController (ForceUpdate)
- (void)showForceUpdateIfNeeeded;
@end

@implementation AppController
@synthesize window = _window;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.uiState = AppUIStateNotLoaded;
        self.seState = AppSEStateNotLoaded;
        self.blocksToExecute = [NSMutableArray array];
        self.logObserver = [[AVSLogObserver alloc] init];
        self.classyCache = [[ClassyCache alloc] init];
        self.groupIdentifier = [NSString stringWithFormat:@"group.%@", NSBundle.mainBundle.bundleIdentifier];
    }
    return self;
}

- (void)dealloc
{
    [self.zetaUserSession removeAuthenticationObserverForToken:self.authToken];
}

- (void)setUiState:(AppUIState)uiState
{
    DDLogInfo(@"AppController.uiState: %lu -> %lu", (unsigned long)_uiState, (unsigned long)uiState);
    _uiState = uiState;
}

- (void)setSeState:(AppSEState)seState
{
    DDLogInfo(@"seState: %lu -> %lu", (unsigned long)_seState, (unsigned long)seState);
    _seState = seState;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self startSyncEngine:application launchOptions:launchOptions];
    [self loadLaunchControllerIfNeeded];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    self.enteringForeground = YES;
    [self loadAppropriateController];
    self.enteringForeground = NO;

    [[self zetaUserSession] checkIfLoggedInWithCallback:^(BOOL isLoggedIn) {
        if (isLoggedIn) {
            [self uploadAddressBookIfNeeded];
        }
    }];
}

- (void)uploadAddressBookIfNeeded
{
    BOOL addressBookDidBecomeGranted = [AddressBookHelper.sharedHelper accessStatusDidChangeToGranted];
    [AddressBookHelper.sharedHelper startRemoteSearchWithCheckingIfEnoughTimeSinceLast:!addressBookDidBecomeGranted];
    [AddressBookHelper.sharedHelper persistCurrentAccessStatus];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self showForceUpdateIfNeeeded];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    [self.zetaUserSession addCompletionHandlerForBackgroundURLSessionWithIdentifier:identifier handler:completionHandler];
}

#pragma mark - UI Loading

- (void)loadAppropriateController
{
    DDLogInfo(@"loadAppropriateController");
    [self loadLaunchControllerIfNeeded];
    [self loadWindowControllersIfNeeded];
    [self showForceUpdateIfNeeeded];
}

- (void)loadLaunchControllerIfNeeded
{
    if (self.uiState == AppUIStateNotLoaded && ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground || self.enteringForeground)) {
        [self loadLaunchController];
    }
}

- (void)loadLaunchController
{
    DDLogInfo(@"launching UI - START");
    self.uiState = AppUIStateLaunchController;
    
    // setup main window
    self.window = [UIWindow new];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.accessibilityIdentifier = @"ZClientMainWindow";
    
    // Just load the fonts here. Don't load the Magic yet, to avoid to have any problems with zmessaging before we allowed to use it
    LaunchImageViewController *launchController = [[LaunchImageViewController alloc] initWithNibName:nil bundle:nil];

    self.launchImageViewController = launchController;
    self.window.rootViewController = launchController;
    
    [self.window setFrame:[[UIScreen mainScreen] bounds]];
    
    [self.window makeKeyAndVisible];
    
    if (self.seState == AppSEStateMigration) {
        [launchController showLoadingScreen];
    }
    
    DDLogInfo(@"launching UI - END");
}

- (void)loadWindowControllersIfNeeded
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground && ! self.enteringForeground) {
        return;
    }
    
    if (self.uiState == AppUIStateLaunchController && (self.seState == AppSEStateAuthenticated || self.seState == AppSEStateNotAuthenticated) && ![Settings sharedSettings].disableUI) {
        [self loadWindowControllers];
    }
}

/// Loads root view controllers of windows on the next run loop iteration
- (void)loadWindowControllers
{
    if (self.uiState != AppUIStateLaunchController) {
        return;
    }
    
    self.uiState = AppUIStateRootController;

    DDLogInfo(@"loadUserInterface START");
    
    // Load magic
    [MagicConfig sharedConfig];
    
    self.mediaPlaybackManager = [[MediaPlaybackManager alloc] initWithName:@"conversationMedia"];
    if (![Settings sharedSettings].disableAVS) {
        AVSMediaManager *mediaManager = [[AVSProvider shared] mediaManager];
        [mediaManager configureSounds];
        [mediaManager observeSoundConfigurationChanges];
        mediaManager.microphoneMuted = NO;
        mediaManager.speakerEnabled = NO;
        [mediaManager registerMedia:self.mediaPlaybackManager withOptions:@{ @"media": @"external" }];
    }

    // UIColor accent color still relies on magic, so we need to setup Classy after Magic.

    dispatch_async(dispatch_get_main_queue(), ^{

        self.notificationsWindow = [PassthroughWindow new];
        [self setupClassyWithWindows:@[self.window, self.notificationsWindow]];

        // Window creation order is important, main window should be the keyWindow when its done.
        [self loadRootViewController];

        // setup overlay window
        [self loadNotificationWindowRootController];
        
        // Bring them into UI
        [self.window makeKeyAndVisible];
        
        // Notification window has to be on top, so must be made visible last.  Changing the window level is
        // not possible because it has to be below the status bar.
        [self.notificationsWindow makeKeyAndVisible];
        
        // Make sure the main window is the key window
        [self.window makeKeyWindow];
        // Application is started, so we stop the `AppStart` event
        StopWatch *stopWatch = [StopWatch stopWatch];
        StopWatchEvent *appStartEvent = [stopWatch stopEvent:@"AppStart"];
        if (appStartEvent) {
            NSUInteger launchTime = [appStartEvent elapsedTime];
            DDLogDebug(@"App launch time %lums", (unsigned long)launchTime);
            [Analytics.shared tagApplicationLaunchTime:launchTime];
        }
        
        DDLogInfo(@"loadUserInterface END");
    });
}
        
- (void)loadRootViewController
{
    RootViewController *rootVc = [[RootViewController alloc] initWithNibName:nil bundle:nil];
    rootVc.isLoggedIn = self.seState == AppSEStateAuthenticated;
    rootVc.signInErrorCode = self.signInErrorCode;
    
    [UIView transitionWithView:self.window duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.window.rootViewController = rootVc;
    } completion:nil];
    [self.window setFrame:[[UIScreen mainScreen] bounds]];
}

- (void)loadNotificationWindowRootController
{
    self.notificationsWindow.backgroundColor = [UIColor clearColor];
    self.notificationsWindow.frame = [[UIScreen mainScreen] bounds];
    self.notificationsWindow.windowLevel = UIWindowLevelStatusBar + 1.0f;
    self.notificationWindowController = [NotificationWindowRootViewController new];
    self.notificationsWindow.rootViewController = self.notificationWindowController;
    self.notificationsWindow.accessibilityIdentifier = @"ZClientNotificationWindow";
    [self.notificationsWindow setHidden:NO];
}

- (void)setupClassyWithWindows:(NSArray *)windows
{
    ColorScheme *colorScheme = [ColorScheme defaultColorScheme];
    colorScheme.accentColor = [UIColor accentColor];
    colorScheme.variant = (ColorSchemeVariant)[[Settings sharedSettings] colorScheme];
    
    [CASStyler defaultStyler].cache = self.classyCache;
    [CASStyler bootstrapClassyWithTargetWindows:windows];
    [[CASStyler defaultStyler] applyColorScheme:colorScheme];
    
    
#if TARGET_IPHONE_SIMULATOR
    NSString *absoluteFilePath = CASAbsoluteFilePath(@"../Resources/Classy/stylesheet.cas");
    int fileDescriptor = open([absoluteFilePath UTF8String], O_EVTONLY);
    if (fileDescriptor > 0) {
        close(fileDescriptor);
        [CASStyler defaultStyler].watchFilePath = absoluteFilePath;
    } else {
        DDLogInfo(@"Unable to watch file: %@; Classy live updates are disabled.", absoluteFilePath);
    }
#endif

}

#pragma mark - SE Loading

- (BOOL)startSyncEngine:(UIApplication *)application launchOptions:(NSDictionary *)launchOptions
{
    dispatch_block_t configuration = ^() {
        
        [self loadUserSession];
        [[ZMUserSession sharedSession] application:application didFinishLaunchingWithOptions:launchOptions];
        
        if (launchOptions[UIApplicationLaunchOptionsURLKey] != nil) {
            [[ZMUserSession sharedSession] didLaunchWithURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
        }
            
        @weakify(self)
        [[ZMUserSession sharedSession] startAndCheckClientVersionWithCheckInterval:Settings.sharedSettings.blacklistDownloadInterval blackListedBlock:^{
            @strongify(self)
            self.seState = AppSEStateBlacklisted;
            [self showForceUpdateIfNeeeded];
        }];
    };
    
    
    if ([ZMUserSession needsToPrepareLocalStoreUsingAppGroupIdentifier:self.groupIdentifier]) {
        self.seState = AppSEStateMigration;
        [self.launchImageViewController showLoadingScreen];
        
        DDLogInfo(@"Database migration required, performing migration now:");
        NSTimeInterval timeStart = [NSDate timeIntervalSinceReferenceDate];
        [ZMUserSession prepareLocalStoreUsingAppGroupIdentifier:self.groupIdentifier completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSTimeInterval timeEnd = [NSDate timeIntervalSinceReferenceDate];
                DDLogInfo(@"Database migration DONE: %.02f sec", timeEnd - timeStart);
                configuration();
            });
        }];
        return NO;
    }
    else {
        DDLogInfo(@"Database migration not required");
        configuration();
        return YES;
    }
    
}

- (ZMUserSession *)zetaUserSession
{
    NSAssert(_zetaUserSession != nil, @"Attempt to access user session before it's ready");
    return _zetaUserSession;
}

- (void)loadUserSession
{
    NSString *BackendEnvironmentTypeKey = @"ZMBackendEnvironmentType";
    NSString *backendEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:BackendEnvironmentTypeKey];
    [[NSUserDefaults sharedUserDefaults] setObject:backendEnvironment forKey:BackendEnvironmentTypeKey];
    
    if (backendEnvironment.length == 0 || [backendEnvironment isEqualToString:@"default"]) {
        NSString *defaultBackend = @STRINGIZE(DEFAULT_BACKEND);
        
        DDLogInfo(@"Backend environment is <not defined>. Using '%@'.", defaultBackend);
        [[NSUserDefaults standardUserDefaults] setObject:defaultBackend forKey:BackendEnvironmentTypeKey];
        [[NSUserDefaults sharedUserDefaults] setObject:defaultBackend forKey:BackendEnvironmentTypeKey];
    } else {
        DDLogInfo(@"Using '%@' backend environment", backendEnvironment);
    }
    
    (void)[Settings sharedSettings];

    BOOL callKitSupported = ([CXCallObserver class] != nil) && !TARGET_IPHONE_SIMULATOR;
    BOOL callKitDisabled = [[Settings sharedSettings] disableCallKit];
    
    [ZMUserSession setUseCallKit:callKitSupported && !callKitDisabled];
    [ZMUserSession setCallingProtocolStrategy:[[Settings sharedSettings] callingProtocolStrategy]];
    
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *appVersion = [[bundle infoDictionary] objectForKey:(NSString *) kCFBundleVersionKey];
    NSString *groupIdentifier = [NSString stringWithFormat:@"group.%@", bundle.bundleIdentifier];
    
    _zetaUserSession = [[ZMUserSession alloc] initWithMediaManager:(id)AVSProvider.shared.mediaManager
                                                         analytics:Analytics.shared
                                                        appVersion:appVersion
                                                appGroupIdentifier:groupIdentifier];

    // Cache conversation lists etc.
    self.sessionObjectCache = [[SessionObjectCache alloc] initWithUserSession:[ZMUserSession sharedSession]];
        
    // Sign up for authentication notifications
    self.authToken = [[ZMUserSession sharedSession] addAuthenticationObserver:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMUserSessionDidBecomeAvailableNotification object:nil];
    [self executeQueuedBlocksIfNeeded];
    
    // Singletons
    AddressBookHelper.sharedHelper.configuration = AutomationHelper.sharedHelper;
}

#pragma mark - User Session block queueing

- (void)performAfterUserSessionIsInitialized:(dispatch_block_t)block
{
    if (nil == block) {
        return;
    }
    
    if (nil != _zetaUserSession) {
        block();
    } else {
        DDLogInfo(@"UIApplicationDelegate method invoked before user session initialization, enqueueing it for later execution.");
        [self.blocksToExecute addObject:block];
    }
}

- (void)executeQueuedBlocksIfNeeded
{
    if (self.blocksToExecute.count > 0) {
        NSArray *blocks = self.blocksToExecute.copy;
        [self.blocksToExecute removeAllObjects];
        
        for (dispatch_block_t block in blocks) {
            block();
        }
    }
}

@end



@implementation AppController (ForceUpdate)

- (void)showForceUpdateIfNeeeded
{
    if (self.uiState == AppUIStateNotLoaded || self.seState != AppSEStateBlacklisted) {
        return;
    }
    
    UIAlertView *forceUpdateAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"force.update.title", nil)
                                                                   message:NSLocalizedString(@"force.update.message", nil)
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"force.update.ok_button", nil)
                                                         otherButtonTitles:nil];
    [forceUpdateAlertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *iTunesLink = @"https://itunes.apple.com/us/app/wire/id930944768?mt=8";
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}

@end


@implementation AppController (AuthObserver)

- (void)authenticationDidSucceed
{
    self.seState = AppSEStateAuthenticated;
    if (!AutomationHelper.sharedHelper.skipFirstLoginAlerts) {
        [[ZMUserSession sharedSession] setupPushNotificationsForApplication:[UIApplication sharedApplication]];
    }
    [self loadAppropriateController];
}

- (void)authenticationDidFail:(NSError *)error
{
    self.seState = AppSEStateNotAuthenticated;
    
    self.signInErrorCode = error.code;
    
    if(error.code == ZMUserSessionClientDeletedRemotely) {
        [self.window.rootViewController showAlertForError:error];
    }
    
    [self loadAppropriateController];
    DDLogInfo(@"Authentication failed: %@", error);
}

@end

