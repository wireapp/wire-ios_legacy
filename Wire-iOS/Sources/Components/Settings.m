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
#import "WireSyncEngine+iOS.h"
#import "avs+iOS.h"
#import "Wire-Swift.h"

NSString * const SettingsColorSchemeChangedNotification = @"SettingsColorSchemeChangedNotification";

// NB!!! After adding the key here please make sure to add it to @m +allDefaultsKeys as well
NSString * const UserDefaultDisableMarkdown = @"UserDefaultDisableMarkdown";
NSString * const UserDefaultChatHeadsDisabled = @"ZDevOptionChatHeadsDisabled";
NSString * const UserDefaultLastPushAlertDate = @"LastPushAlertDate";
NSString * const UserDefaultVoIPNotificationsOnly = @"VoIPNotificationsOnly";

NSString * const UserDefaultLastViewedConversation = @"LastViewedConversation";
NSString * const UserDefaultColorScheme = @"ColorScheme";
NSString * const UserDefaultLastViewedScreen = @"LastViewedScreen";
NSString * const UserDefaultPreferredCameraFlashMode = @"PreferredCameraFlashMode";
NSString * const UserDefaultPreferredCamera = @"PreferredCamera";
NSString * const AVSMediaManagerPersistentIntensity = @"AVSMediaManagerPersistentIntensity";
NSString * const UserDefaultLastUserLocation = @"LastUserLocation";

NSString * const BlackListDownloadIntervalKey = @"ZMBlacklistDownloadInterval";

NSString * const UserDefaultMessageSoundName = @"ZMMessageSoundName";
NSString * const UserDefaultCallSoundName = @"ZMCallSoundName";
NSString * const UserDefaultPingSoundName = @"ZMPingSoundName";

NSString * const UserDefaultSendButtonDisabled = @"SendButtonDisabled";
NSString * const UserDefaultDisableCallKit = @"UserDefaultDisableCallKit";

NSString * const UserDefaultEnableBatchCollections = @"UserDefaultEnableBatchCollections";


NSString * const UserDefaultCallingProtocolStrategy = @"CallingProtocolStrategy";

NSString * const UserDefaultTwitterOpeningRawValue = @"TwitterOpeningRawValue";
NSString * const UserDefaultMapsOpeningRawValue = @"MapsOpeningRawValue";
NSString * const UserDefaultBrowserOpeningRawValue = @"BrowserOpeningRawValue";
NSString * const UserDefaultDidMigrateHockeySettingInitially = @"DidMigrateHockeySettingInitially";

NSString * const UserDefaultCallingConstantBitRate = @"CallingConstantBitRate";

NSString * const UserDefaultDisableLinkPreviews = @"DisableLinkPreviews";

@interface Settings ()

@property (strong, readonly, nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSTimeInterval maxRecordingDurationDebug;
@end



@interface Settings (MediaManager)

- (void)restoreLastUsedAVSSettings;
- (void)storeCurrentIntensityLevelAsLastUsed;

@end



@implementation Settings

+ (NSArray *)allDefaultsKeys
{
    return @[UserDefaultDisableMarkdown,
             UserDefaultChatHeadsDisabled,
             UserDefaultLastViewedConversation,
             UserDefaultLastViewedScreen,
             AVSMediaManagerPersistentIntensity,
             UserDefaultPreferredCameraFlashMode,
             UserDefaultLastPushAlertDate,
             BlackListDownloadIntervalKey,
             UserDefaultMessageSoundName,
             UserDefaultCallSoundName,
             UserDefaultPingSoundName,
             UserDefaultLastUserLocation,
             UserDefaultPreferredCamera,
             UserDefaultSendButtonDisabled,
             UserDefaultDisableCallKit,
             UserDefaultTwitterOpeningRawValue,
             UserDefaultMapsOpeningRawValue,
             UserDefaultBrowserOpeningRawValue,
             UserDefaultCallingProtocolStrategy,
             UserDefaultEnableBatchCollections,
             UserDefaultDidMigrateHockeySettingInitially,
             UserDefaultCallingConstantBitRate,
             UserDefaultDisableLinkPreviews,
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
        [self migrateHockeyAndOptOutSettingsToSharedDefaults];
        [self restoreLastUsedAVSSettings];
        
#if !(TARGET_OS_SIMULATOR)
        [self loadEnabledLogs];
#else
        [ZMSLog startRecordingWithIsInternal:[DeveloperMenuState developerMenuEnabled]];
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (NSUserDefaults *)defaults
{
    return [NSUserDefaults standardUserDefaults];
}

- (void)migrateHockeyAndOptOutSettingsToSharedDefaults
{
    if (! [self.defaults boolForKey:UserDefaultDidMigrateHockeySettingInitially]) {
        ExtensionSettings.shared.disableLinkPreviews = self.disableLinkPreviews;
        [self.defaults setBool:YES forKey:UserDefaultDidMigrateHockeySettingInitially];
    }
}

- (BOOL)disableMarkdown
{
    return [self.defaults boolForKey:UserDefaultDisableMarkdown];
}

- (void)setDisableMarkdown:(BOOL)disableMarkdown
{
    [self.defaults setBool:disableMarkdown forKey:UserDefaultDisableMarkdown];
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

- (NSDate *)lastPushAlertDate
{
    return [self.defaults objectForKey:UserDefaultLastPushAlertDate];
}

- (void)setLastPushAlertDate:(NSDate *)lastPushAlertDate
{
    [self.defaults setObject:lastPushAlertDate forKey:UserDefaultLastPushAlertDate];
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

- (SettingsCamera)preferredCamera
{
    return [self.defaults integerForKey:UserDefaultPreferredCamera];
}

- (void)setPreferredCamera:(SettingsCamera)preferredCamera
{
    [self.defaults setInteger:preferredCamera forKey:UserDefaultPreferredCamera];
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
    [AVSMediaManager.sharedInstance configureSounds];
}

- (NSString *)messageSoundName
{
    return [self.defaults objectForKey:UserDefaultMessageSoundName];
}

- (void)setCallSoundName:(NSString *)callSoundName
{
    [self.defaults setObject:callSoundName forKey:UserDefaultCallSoundName];
    [AVSMediaManager.sharedInstance configureSounds];
}

- (NSString *)callSoundName
{
    return [self.defaults objectForKey:UserDefaultCallSoundName];
}

- (void)setPingSoundName:(NSString *)pingSoundName
{
    [self.defaults setObject:pingSoundName forKey:UserDefaultPingSoundName];
    [AVSMediaManager.sharedInstance configureSounds];
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
    [[SessionManager shared] updateCallNotificationStyleFromSettings];
}

- (BOOL)disableLinkPreviews
{
    return ExtensionSettings.shared.disableLinkPreviews;
}

- (void)setDisableLinkPreviews:(BOOL)disableLinkPreviews
{
    ExtensionSettings.shared.disableLinkPreviews = disableLinkPreviews;
    [self.defaults synchronize];
}

#pragma mark - Features disable keys

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

- (BOOL)callingConstantBitRate
{
    return [self.defaults boolForKey:UserDefaultCallingConstantBitRate];
}

- (void)setCallingConstantBitRate:(BOOL)callingConstantBitRate
{
    [self.defaults setBool:callingConstantBitRate forKey:UserDefaultCallingConstantBitRate];
    SessionManager.shared.useConstantBitRateAudio = callingConstantBitRate;
}

@end

@implementation Settings (MediaManager)

- (void)restoreLastUsedAVSSettings
{
    NSNumber *savedIntensity = [self.defaults objectForKey:AVSMediaManagerPersistentIntensity];
    AVSIntensityLevel level = (AVSIntensityLevel)[savedIntensity integerValue];
    if (savedIntensity == nil) {
        level = AVSIntensityLevelFull;
    }
    
    AVSMediaManager.sharedInstance.intensityLevel = level;
}

- (void)storeCurrentIntensityLevelAsLastUsed
{
    AVSIntensityLevel level = AVSMediaManager.sharedInstance.intensityLevel;
    if (level >= AVSIntensityLevelNone && level <= AVSIntensityLevelFull) {
        [self.defaults setObject:[NSNumber numberWithInt:level] forKey:AVSMediaManagerPersistentIntensity];
    }
}

@end

