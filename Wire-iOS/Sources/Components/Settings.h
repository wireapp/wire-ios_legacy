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


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@import WireSyncEngine;

@class ZMLocationData;
@class ZMConversation;
@class ZMEmailCredentials;

typedef NS_ENUM(NSUInteger, SettingsColorScheme) {
    SettingsColorSchemeLight,
    SettingsColorSchemeDark
};

typedef NS_ENUM (NSUInteger, SettingsLastScreen) {
    SettingsLastScreenNone = 0,
    SettingsLastScreenList,
    SettingsLastScreenConversation
};

typedef NS_ENUM (NSUInteger, SettingsCamera) {
    SettingsCameraFront,
    SettingsCameraBack
};

extern NSString * const SettingsColorSchemeChangedNotification;

extern NSString * const UserDefaultDisableMarkdown;
extern NSString * const UserDefaultChatHeadsDisabled;
extern NSString * const UserDefaultLastPushAlertDate;

extern NSString * const UserDefaultLastViewedConversation;
extern NSString * const UserDefaultColorScheme;
extern NSString * const UserDefaultLastViewedScreen;
extern NSString * const UserDefaultPreferredCamera;
extern NSString * const UserDefaultPreferredCameraFlashMode;
extern NSString * const AVSMediaManagerPersistentIntensity;
extern NSString * const UserDefaultLastUserLocation;

extern NSString * const BlackListDownloadIntervalKey;

extern NSString * const UserDefaultMessageSoundName;
extern NSString * const UserDefaultCallSoundName;
extern NSString * const UserDefaultPingSoundName;

extern NSString * const UserDefaultDisableCallKit;

extern NSString * const UserDefaultEnableBatchCollections;

extern NSString * const UserDefaultSendButtonDisabled;

extern NSString * const UserDefaultCallingProtocolStrategy;

extern NSString * const UserDefaultTwitterOpeningRawValue;
extern NSString * const UserDefaultMapsOpeningRawValue;
extern NSString * const UserDefaultBrowserOpeningRawValue;

extern NSString * const UserDefaultCallingConstantBitRate;

extern NSString * const UserDefaultDisableLinkPreviews;

/// Model object for locally stored (not in SE or AVS) user app settings
@interface Settings : NSObject

@property (nonatomic) BOOL chatHeadsDisabled;
@property (nonatomic) BOOL disableMarkdown;
@property (nonatomic) BOOL shouldRegisterForVoIPNotificationsOnly;
@property (nonatomic) BOOL disableSendButton;
@property (nonatomic) BOOL disableLinkPreviews;

@property (nonatomic) BOOL disableCallKit;
@property (nonatomic) BOOL callingConstantBitRate;

@property (nonatomic) BOOL enableBatchCollections; // develop option

@property (nonatomic) NSDate *lastPushAlertDate;

@property (nonatomic) SettingsLastScreen lastViewedScreen;
@property (nonatomic) SettingsCamera preferredCamera;
@property (nonatomic) SettingsColorScheme colorScheme;
@property (nonatomic, readonly) NSTimeInterval blacklistDownloadInterval;
@property (nonatomic) ZMLocationData *lastUserLocation;

@property (nonatomic) NSString *messageSoundName;
@property (nonatomic) NSString *callSoundName;
@property (nonatomic) NSString *pingSoundName;

@property (nonatomic) NSInteger twitterLinkOpeningOptionRawValue;
@property (nonatomic) NSInteger browserLinkOpeningOptionRawValue;
@property (nonatomic) NSInteger mapsLinkOpeningOptionRawValue;

+ (instancetype)sharedSettings;

// Persist all the settings
- (void)synchronize;

- (void)reset;

- (NSUserDefaults *)defaults;

@end


/// These settings are not actually persisted, just kept in memory
@interface Settings (Debug)

// Max audio recording duration in seconds
@property (nonatomic) NSTimeInterval maxRecordingDurationDebug;

@end
