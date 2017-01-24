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


#import "Settings.h"
#import "Settings+ColorScheme.h"
#import "zmessaging+iOS.h"
#import "avs+iOS.h"
#import "Wire-Swift.h"

NSString * const SettingsColorSchemeChangedNotification = @"SettingsColorSchemeChangedNotification";

// NB!!! After adding the key here please make sure to add it to @m +allDefaultsKeys as well
NSString * const UserDefaultExtras = @"ZDevOptionExtras";
NSString * const UserDefaultMarkdown = @"UserDefaultMarkdown";
NSString * const UserDefaultChatHeadsDisabled = @"ZDevOptionChatHeadsDisabled";
NSString * const UserDefaultLikeTutorialCompleted = @"LikeTutorialCompleted";
NSString * const UserDefaultLastPushAlertDate = @"LastPushAlertDate";
NSString * const UserDefaultVoIPNotificationsOnly = @"VoIPNotificationsOnly";

NSString * const UserDefaultContactTipWasDisplayed =  @"ContactTipWasDisplayed";
NSString * const UserDefaultLastViewedConversation = @"LastViewedConversation";
NSString * const UserDefaultColorScheme = @"ColorScheme";
NSString * const UserDefaultLastViewedScreen = @"LastViewedScreen";
NSString * const UserDefaultPreferredCameraFlashMode = @"PreferredCameraFlashMode";
NSString * const UserDefaultPreferredCamera = @"PreferredCamera";
NSString * const AVSMediaManagerPersistentIntensity = @"AVSMediaManagerPersistentIntensity";
NSString * const UserDefaultLastUserLocation = @"LastUserLocation";

NSString * const UserDefaultSkipFirstTimeUseChecks = @"SkipFirstTimeUseChecks";
NSString * const BlackListDownloadIntervalKey = @"ZMBlacklistDownloadInterval";

NSString * const UserDefaultMessageSoundName = @"ZMMessageSoundName";
NSString * const UserDefaultCallSoundName = @"ZMCallSoundName";
NSString * const UserDefaultPingSoundName = @"ZMPingSoundName";

NSString * const UserDefaultDisableAVS = @"ZMDisableAVS";
NSString * const UserDefaultDisableUI = @"ZMDisableUI";
NSString * const UserDefaultDisableHockey = @"ZMDisableHockey";
NSString * const UserDefaultDisableAnalytics = @"ZMDisableAnalytics";
NSString * const UserDefaultSendButtonDisabled = @"SendButtonDisabled";
NSString * const UserDefaultDisableCallKit = @"UserDefaultDisableCallKit";

NSString * const UserDefaultEnableBatchCollections = @"UserDefaultEnableBatchCollections";


NSString * const UserDefaultSendV3Assets = @"SendV3Assets";
NSString * const UserDefaultCallingProtocolStrategy = @"CallingProtocolStrategy";

NSString * const UserDefaultTwitterOpeningRawValue = @"TwitterOpeningRawValue";
NSString * const UserDefaultMapsOpeningRawValue = @"MapsOpeningRawValue";
NSString * const UserDefaultBrowserOpeningRawValue = @"BrowserOpeningRawValue";


@interface Settings ()

@property (strong, readonly, nonatomic) NSUserDefaults *defaults;
@property (nonatomic, strong) ZMConversation *lastViewedConversationInternal;
@property (nonatomic) BOOL shouldSend500Messages;
@property (nonatomic) NSTimeInterval maxRecordingDurationDebug;
@property (nonatomic) ZMEmailCredentials *automationTestEmailCredentials;

@end



@interface Settings (MediaManager)

- (void)restoreLastUsedIntensityLevel;
- (void)storeCurrentIntensityLevelAsLastUsed;

@end



@implementation Settings

+ (NSArray *)allDefaultsKeys
{
    return @[UserDefaultMarkdown,
             UserDefaultChatHeadsDisabled,
             UserDefaultLikeTutorialCompleted,
             UserDefaultLastViewedConversation,
             UserDefaultLastViewedScreen,
             AVSMediaManagerPersistentIntensity,
             UserDefaultSkipFirstTimeUseChecks,
             UserDefaultPreferredCameraFlashMode,
             UserDefaultLastPushAlertDate,
             BlackListDownloadIntervalKey,
             UserDefaultContactTipWasDisplayed,
             UserDefaultMessageSoundName,
             UserDefaultCallSoundName,
             UserDefaultPingSoundName,
             UserDefaultDisableAVS,
             UserDefaultDisableUI,
             UserDefaultDisableHockey,
             UserDefaultDisableAnalytics,
             UserDefaultLastUserLocation,
             UserDefaultPreferredCamera,
             UserDefaultSendButtonDisabled,
             UserDefaultDisableCallKit,
             UserDefaultTwitterOpeningRawValue,
             UserDefaultMapsOpeningRawValue,
             UserDefaultBrowserOpeningRawValue,
             UserDefaultSendV3Assets,
             UserDefaultCallingProtocolStrategy,
             UserDefaultEnableBatchCollections,
             ];
}

+ (instancetype)sharedSettings
{
    static Settings *sharedSettings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettings = [[self alloc] init];
    });
    
    return sharedSettings;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self restoreLastUsedIntensityLevel];
        [self loadEnabledLogs];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSUserDefaults *)defaults
{
    return [NSUserDefaults standardUserDefaults];
}

- (BOOL)enableExtras
{
    return [self.defaults boolForKey:UserDefaultExtras];
}

- (void)setEnableExtras:(BOOL)enableExtras
{
    [self.defaults setBool:enableExtras forKey:UserDefaultExtras];
    [self.defaults synchronize];
}

- (BOOL)contactTipWasDisplayed
{
    return [self.defaults boolForKey:UserDefaultContactTipWasDisplayed];
}

- (void)setContactTipWasDisplayed:(BOOL)contactTipWasDisplayed
{
    [self.defaults setBool:contactTipWasDisplayed forKey:UserDefaultContactTipWasDisplayed];
    [self.defaults synchronize];
}

- (BOOL)enableMarkdown
{
    return [self.defaults boolForKey:UserDefaultMarkdown];
}

- (void)setEnableMarkdown:(BOOL)enableMarkdown
{
    [self.defaults setBool:enableMarkdown forKey:UserDefaultMarkdown];
    [self.defaults synchronize];
}

- (BOOL)chatHeadsDisabled
{
    return [self.defaults boolForKey:UserDefaultChatHeadsDisabled];
}

- (void)setChatHeadsDisabled:(BOOL)chatHeadsDisabled
{
    [self.defaults setBool:chatHeadsDisabled forKey:UserDefaultChatHeadsDisabled];
    [self.defaults synchronize];
}

- (BOOL)skipFirstTimeUseChecks
{
    return [self.defaults boolForKey:UserDefaultSkipFirstTimeUseChecks];
}

- (NSDate *)lastPushAlertDate
{
    return [self.defaults objectForKey:UserDefaultLastPushAlertDate];
}

- (void)setLastPushAlertDate:(NSDate *)lastPushAlertDate
{
    [self.defaults setObject:lastPushAlertDate forKey:UserDefaultLastPushAlertDate];
    [self.defaults synchronize];
}

- (ZMConversation *)lastViewedConversation
{
    if (self.lastViewedConversationInternal == nil) {
        NSString *convString = [self.defaults objectForKey:UserDefaultLastViewedConversation];
        NSURL *rememberedConvUrl = [NSURL URLWithString:convString];
        
        ZMUserSession *session = [ZMUserSession sharedSession];
        NSManagedObjectID *objectID = [ZMManagedObject objectIDForURIRepresentation:rememberedConvUrl inUserSession:session];
        
        ZMConversation *conversation = [ZMConversation existingObjectWithID:objectID inUserSession:session];
        self.lastViewedConversationInternal = conversation;
    }
    return self.lastViewedConversationInternal;
}

- (void)setLastViewedConversation:(ZMConversation *)lastViewedConversation
{
    self.lastViewedConversationInternal = lastViewedConversation;
    NSURL *selectedConversationURI = [lastViewedConversation.objectID URIRepresentation];
    [self.defaults setObject:[selectedConversationURI absoluteString] forKey:UserDefaultLastViewedConversation];
    [self.defaults synchronize];
}

- (SettingsLastScreen)lastViewedScreen
{
    SettingsLastScreen lastScreen = [self.defaults integerForKey:UserDefaultLastViewedScreen];
    return lastScreen;
}

- (void)setLastViewedScreen:(SettingsLastScreen)lastViewedScreen
{
    [self.defaults setInteger:lastViewedScreen forKey:UserDefaultLastViewedScreen];
    [self.defaults synchronize];
}

- (ZMLocationData *)lastUserLocation
{
    NSDictionary *locationDict = [self.defaults objectForKey:UserDefaultLastUserLocation];
    return [ZMLocationData locationDataFromDictionary:locationDict];
}

- (void)setLastUserLocation:(ZMLocationData *)lastUserLocation
{
    NSDictionary *locationDict = lastUserLocation.toDictionary;
    [self.defaults setObject:locationDict forKey:UserDefaultLastUserLocation];
}

- (AVCaptureFlashMode)preferredFlashMode
{
    AVCaptureFlashMode preferedCameraFlashMode = [self.defaults integerForKey:UserDefaultPreferredCameraFlashMode];
    return preferedCameraFlashMode;
}

- (void)setPreferredFlashMode:(AVCaptureFlashMode)preferredFlashMode
{
    [self.defaults setInteger:preferredFlashMode forKey:UserDefaultPreferredCameraFlashMode];
    [self.defaults synchronize];
}

- (CameraControllerCamera)preferredCamera
{
    return [self.defaults integerForKey:UserDefaultPreferredCamera];
}

- (void)setPreferredCamera:(CameraControllerCamera)preferredCamera
{
    [self.defaults setInteger:preferredCamera forKey:UserDefaultPreferredCamera];
}

- (BOOL)likeTutorialCompleted
{
    return [self.defaults boolForKey:UserDefaultLikeTutorialCompleted];
}

- (void)setLikeTutorialCompleted:(BOOL)likeTutorialCompleted
{
    [self.defaults setBool:likeTutorialCompleted forKey:UserDefaultLikeTutorialCompleted];
    [self.defaults synchronize];
}

- (void)synchronize
{
    [self storeCurrentIntensityLevelAsLastUsed];
    
    [self.defaults synchronize];
}

- (SettingsColorScheme)colorScheme
{
    return [self colorSchemeFromString:[self.defaults objectForKey:UserDefaultColorScheme]];
}

- (void)setColorScheme:(SettingsColorScheme)colorScheme
{
    [self.defaults setObject:[self stringForColorScheme:colorScheme] forKey:UserDefaultColorScheme];
    [self.defaults synchronize];
    [self notifyColorSchemeChanged];
}

- (void)notifyColorSchemeChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SettingsColorSchemeChangedNotification object:self userInfo:nil];
}

- (NSTimeInterval)blacklistDownloadInterval
{
    const NSInteger HOURS_6 = 6 * 60 * 60;
    NSInteger settingValue = [self.defaults integerForKey:BlackListDownloadIntervalKey];
    return settingValue > 0 ? settingValue : HOURS_6;
}

- (void)reset
{
    for (NSString *key in self.class.allDefaultsKeys) {
        [self.defaults removeObjectForKey:key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self synchronize];
}

- (BOOL)shouldRegisterForVoIPNotificationsOnly
{
    return [self.defaults boolForKey:UserDefaultVoIPNotificationsOnly];
}

- (void)setShouldRegisterForVoIPNotificationsOnly:(BOOL)shoudlRegisterForVoIPOnly
{
    [self.defaults setBool:shoudlRegisterForVoIPOnly forKey:UserDefaultVoIPNotificationsOnly];
    [self.defaults synchronize];
}

- (void)setMessageSoundName:(NSString *)messageSoundName
{
    [self.defaults setObject:messageSoundName forKey:UserDefaultMessageSoundName];
    [[[AVSProvider shared] mediaManager] configureSounds];
}

- (NSString *)messageSoundName
{
    return [self.defaults objectForKey:UserDefaultMessageSoundName];
}

- (void)setCallSoundName:(NSString *)callSoundName
{
    [self.defaults setObject:callSoundName forKey:UserDefaultCallSoundName];
    [[[AVSProvider shared] mediaManager] configureSounds];
}

- (NSString *)callSoundName
{
    return [self.defaults objectForKey:UserDefaultCallSoundName];
}

- (void)setPingSoundName:(NSString *)pingSoundName
{
    [self.defaults setObject:pingSoundName forKey:UserDefaultPingSoundName];
    [[[AVSProvider shared] mediaManager] configureSounds];
}

- (NSString *)pingSoundName
{
    return [self.defaults objectForKey:UserDefaultPingSoundName];
}

- (BOOL)disableSendButton
{
    return [self.defaults boolForKey:UserDefaultSendButtonDisabled];
}

- (void)setDisableSendButton:(BOOL)disableSendButton
{
    [self.defaults setBool:disableSendButton forKey:UserDefaultSendButtonDisabled];
}

- (BOOL)disableCallKit
{
    return [self.defaults boolForKey:UserDefaultDisableCallKit];
}

- (void)setDisableCallKit:(BOOL)disableCallKit
{
    [self.defaults setBool:disableCallKit forKey:UserDefaultDisableCallKit];
}

#pragma mark - Features disable keys

- (BOOL)disableUI
{
    return [self.defaults boolForKey:UserDefaultDisableUI];
}

- (void)setDisableUI:(BOOL)disableUI
{
    [self.defaults setBool:disableUI forKey:UserDefaultDisableUI];
    [self.defaults synchronize];
}

- (BOOL)disableAVS
{
    return [self.defaults boolForKey:UserDefaultDisableAVS];
}

- (void)setDisableAVS:(BOOL)disableAVS
{
    [self.defaults setBool:disableAVS forKey:UserDefaultDisableAVS];
    [self.defaults synchronize];
}

- (BOOL)disableHockey
{
    return [self.defaults boolForKey:UserDefaultDisableHockey];
}

- (void)setDisableHockey:(BOOL)disableHockey
{
    [self.defaults setBool:disableHockey forKey:UserDefaultDisableHockey];
    [self.defaults synchronize];
}

- (BOOL)disableAnalytics
{
    return [self.defaults boolForKey:UserDefaultDisableAnalytics];
}

- (void)setDisableAnalytics:(BOOL)disableAnalytics
{
    [self.defaults setBool:disableAnalytics forKey:UserDefaultDisableAnalytics];
    [self.defaults synchronize];
}

- (BOOL)sendV3Assets
{
    return [self.defaults boolForKey:UserDefaultSendV3Assets];
}

- (void)setSendV3Assets:(BOOL)sendV3Assets
{
    [self.defaults setBool:sendV3Assets forKey:UserDefaultSendV3Assets];
}

- (void)setCallingProtocolStrategy:(CallingProtocolStrategy)callingProtocolStrategy
{
    [self.defaults setInteger:callingProtocolStrategy forKey:UserDefaultCallingProtocolStrategy];
}

- (CallingProtocolStrategy)callingProtocolStrategy
{
    return [self.defaults integerForKey:UserDefaultCallingProtocolStrategy];
}

- (BOOL)enableBatchCollections
{
    return [self.defaults boolForKey:UserDefaultEnableBatchCollections];
}

- (void)setEnableBatchCollections:(BOOL)enableBatchCollections
{
    [self.defaults setBool:enableBatchCollections forKey:UserDefaultEnableBatchCollections];
}

#pragma mark - Link opening options

- (NSInteger)twitterLinkOpeningOptionRawValue
{
    return [self.defaults integerForKey:UserDefaultTwitterOpeningRawValue];
}

- (void)setTwitterLinkOpeningOptionRawValue:(NSInteger)twitterLinkOpeningOptionRawValue
{
    [self.defaults setInteger:twitterLinkOpeningOptionRawValue forKey:UserDefaultTwitterOpeningRawValue];
}

- (NSInteger)mapsLinkOpeningOptionRawValue
{
    return [self.defaults integerForKey:UserDefaultMapsOpeningRawValue];
}

- (void)setMapsLinkOpeningOptionRawValue:(NSInteger)mapsLinkOpeningOptionRawValue
{
    [self.defaults setInteger:mapsLinkOpeningOptionRawValue forKey:UserDefaultMapsOpeningRawValue];
}

- (NSInteger)browserLinkOpeningOptionRawValue
{
    return [self.defaults integerForKey:UserDefaultBrowserOpeningRawValue];
}

- (void)setBrowserLinkOpeningOptionRawValue:(NSInteger)browserLinkOpeningOptionRawValue
{
    [self.defaults setInteger:browserLinkOpeningOptionRawValue forKey:UserDefaultBrowserOpeningRawValue];
}

@end

@implementation Settings (MediaManager)

- (void)restoreLastUsedIntensityLevel
{
    NSNumber *savedIntensity = [self.defaults objectForKey:AVSMediaManagerPersistentIntensity];
    AVSIntensityLevel level = (AVSIntensityLevel)[savedIntensity integerValue];
    if (savedIntensity == nil) {
        level = AVSIntensityLevelFull;
    }
    
    [[AVSProvider shared] mediaManager].intensityLevel = level;
}

- (void)storeCurrentIntensityLevelAsLastUsed
{
    AVSIntensityLevel level = [[AVSProvider shared] mediaManager].intensityLevel;
    if (level >= AVSIntensityLevelNone && level <= AVSIntensityLevelFull) {
        [self.defaults setObject:[NSNumber numberWithInt:level] forKey:AVSMediaManagerPersistentIntensity];
    }
}

@end

