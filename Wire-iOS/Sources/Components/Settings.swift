
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation

enum SettingsLastScreen : Int {
    case none = 0
    case list
    case conversation
}

enum SettingsCamera : Int {
    case front
    case back
}

//let SettingsColorSchemeChangedNotification: String? = nil
//let UserDefaultDisableMarkdown: String? = nil
//let UserDefaultChatHeadsDisabled: String? = nil
//let UserDefaultLastPushAlertDate: String? = nil
//let UserDefaultLastViewedConversation: String? = nil
//let UserDefaultColorScheme: String? = nil
//let UserDefaultLastViewedScreen: String? = nil
//let UserDefaultPreferredCamera: String? = nil
//let UserDefaultPreferredCameraFlashMode: String? = nil
//let AVSMediaManagerPersistentIntensity: String? = nil
//let UserDefaultLastUserLocation: String? = nil
//let BlackListDownloadIntervalKey: String? = nil
//let UserDefaultMessageSoundName: String? = nil
//let UserDefaultCallSoundName: String? = nil
//let UserDefaultPingSoundName: String? = nil
//
//let UserDefaultDisableCallKit: String? = nil
//let UserDefaultEnableBatchCollections: String? = nil
//let UserDefaultSendButtonDisabled: String? = nil
//let UserDefaultCallingProtocolStrategy: String? = nil
//let UserDefaultTwitterOpeningRawValue: String? = nil
//let UserDefaultMapsOpeningRawValue: String? = nil
//let UserDefaultBrowserOpeningRawValue: String? = nil
//let UserDefaultCallingConstantBitRate: String? = nil
//let UserDefaultDisableLinkPreviews: String? = nil

let SettingsColorSchemeChangedNotification = "SettingsColorSchemeChangedNotification"
// NB!!! After adding the key here please make sure to add it to @m +allDefaultsKeys as well
let UserDefaultDisableMarkdown = "UserDefaultDisableMarkdown"
let UserDefaultChatHeadsDisabled = "ZDevOptionChatHeadsDisabled"
let UserDefaultLastPushAlertDate = "LastPushAlertDate"
let UserDefaultVoIPNotificationsOnly = "VoIPNotificationsOnly"
let UserDefaultLastViewedConversation = "LastViewedConversation"
let UserDefaultColorScheme = "ColorScheme"
let UserDefaultLastViewedScreen = "LastViewedScreen"
let UserDefaultPreferredCameraFlashMode = "PreferredCameraFlashMode"
let UserDefaultPreferredCamera = "PreferredCamera"
let AVSMediaManagerPersistentIntensity = "AVSMediaManagerPersistentIntensity"
let UserDefaultLastUserLocation = "LastUserLocation"
let BlackListDownloadIntervalKey = "ZMBlacklistDownloadInterval"
let UserDefaultMessageSoundName = "ZMMessageSoundName"
let UserDefaultCallSoundName = "ZMCallSoundName"
let UserDefaultPingSoundName = "ZMPingSoundName"
let UserDefaultSendButtonDisabled = "SendButtonDisabled"
let UserDefaultDisableCallKit = "UserDefaultDisableCallKit"
let UserDefaultEnableBatchCollections = "UserDefaultEnableBatchCollections"
let UserDefaultCallingProtocolStrategy = "CallingProtocolStrategy"
let UserDefaultTwitterOpeningRawValue = "TwitterOpeningRawValue"
let UserDefaultMapsOpeningRawValue = "MapsOpeningRawValue"
let UserDefaultBrowserOpeningRawValue = "BrowserOpeningRawValue"
let UserDefaultDidMigrateHockeySettingInitially = "DidMigrateHockeySettingInitially"
let UserDefaultCallingConstantBitRate = "CallingConstantBitRate"
let UserDefaultDisableLinkPreviews = "DisableLinkPreviews"

/// Model object for locally stored (not in SE or AVS) user app settings
///TODO: no nsobject?
final class Settings: NSObject {
    var chatHeadsDisabled = false
    var disableMarkdown = false
    var shouldRegisterForVoIPNotificationsOnly = false
    var disableSendButton = false
    var disableLinkPreviews = false
    var disableCallKit = false
    var callingConstantBitRate = false
    var enableBatchCollections = false
    /* develop option */    var lastPushAlertDate: Date?
    var lastViewedScreen: SettingsLastScreen?
    var preferredCamera: SettingsCamera?
    private(set) var blacklistDownloadInterval: TimeInterval = 0.0
    var lastUserLocation: ZMLocationData?
    var messageSoundName: String?
    var callSoundName: String?
    var pingSoundName: String?
    var twitterLinkOpeningOptionRawValue = 0
    var browserLinkOpeningOptionRawValue = 0
    var mapsLinkOpeningOptionRawValue = 0
    
    private var maxRecordingDurationDebug: TimeInterval = 0.0

    class func allDefaultsKeys() -> [AnyHashable]? {
        return [
            UserDefaultDisableMarkdown,
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
            UserDefaultDisableLinkPreviews
        ]
    }
    
    static let sharedSettingsVar: Settings? = {
        var sharedSettings = self.init()
        return sharedSettings
    }()
    
    class func sharedSettings() -> Self {
        // `dispatch_once()` call was converted to a static variable initializer
        
        return sharedSettingsVar
    }
    
    override init() {
        super.init()
        migrateAppCenterAndOptOutSettingsToSharedDefaults()
        restoreLastUsedAVSSettings()
        
        startLogging()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func migrateAppCenterAndOptOutSettingsToSharedDefaults() {
        if !defaults.bool(forKey: UserDefaultDidMigrateHockeySettingInitially) {
            ExtensionSettings.shared.disableLinkPreviews = disableLinkPreviews
            defaults.set(true, forKey: UserDefaultDidMigrateHockeySettingInitially)
        }
    }
    
    func disableMarkdown() -> Bool {
        return defaults.bool(forKey: UserDefaultDisableMarkdown)
    }
    
    func setDisableMarkdown(_ disableMarkdown: Bool) {
        defaults.set(disableMarkdown, forKey: UserDefaultDisableMarkdown)
        defaults.synchronize()
    }
    
    func chatHeadsDisabled() -> Bool {
        return defaults.bool(forKey: UserDefaultChatHeadsDisabled)
    }
    
    func setChatHeadsDisabled(_ chatHeadsDisabled: Bool) {
        defaults.set(chatHeadsDisabled, forKey: UserDefaultChatHeadsDisabled)
        defaults.synchronize()
    }
    
    func lastPushAlertDate() -> Date? {
        return defaults[UserDefaultLastPushAlertDate] as? Date
    }
    
    func setLastPushAlert(_ lastPushAlertDate: Date?) {
        defaults[UserDefaultLastPushAlertDate] = lastPushAlertDate
        defaults.synchronize()
    }
    
    func lastViewedScreen() -> SettingsLastScreen {
        let lastScreen = defaults.integer(forKey: UserDefaultLastViewedScreen)
        return lastScreen
    }
    
    func setLastViewedScreen(_ lastViewedScreen: SettingsLastScreen) {
        defaults.set(Int(lastViewedScreen), forKey: UserDefaultLastViewedScreen)
        defaults.synchronize()
    }

    func lastUserLocation() -> ZMLocationData? {
        let locationDict = defaults[UserDefaultLastUserLocation] as? [AnyHashable : Any]
        return ZMLocationData(fromDictionary: locationDict)
    }
    
    func setLastUserLocation(_ lastUserLocation: ZMLocationData?) {
        let locationDict = lastUserLocation?.toDictionary
        defaults[UserDefaultLastUserLocation] = locationDict
    }
    
    func preferredCamera() -> SettingsCamera {
        return defaults.integer(forKey: UserDefaultPreferredCamera)
    }
    
    func setPreferredCamera(_ preferredCamera: SettingsCamera) {
        defaults.set(Int(preferredCamera), forKey: UserDefaultPreferredCamera)
    }
    
    func synchronize() {
        storeCurrentIntensityLevelAsLastUsed()
        
        defaults.synchronize()
    }
    
    func blacklistDownloadInterval() -> TimeInterval {
        let HOURS_6 = 6 * 60 * 60
        let settingValue = defaults.integer(forKey: BlackListDownloadIntervalKey)
        return TimeInterval(settingValue > 0 ? settingValue : HOURS_6)
    }
    
    func reset() {
        for key in type(of: self).allDefaultsKeys {
            defaults.removeObject(forKey: key)
        }
        UserDefaults.standard.synchronize()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        synchronize()
    }
    
    func shouldRegisterForVoIPNotificationsOnly() -> Bool {
        return defaults.bool(forKey: UserDefaultVoIPNotificationsOnly)
    }

    func setShouldRegisterForVoIPNotificationsOnly(_ shoudlRegisterForVoIPOnly: Bool) {
        defaults.set(shoudlRegisterForVoIPOnly, forKey: UserDefaultVoIPNotificationsOnly)
        defaults.synchronize()
    }
    
    func setMessageSoundName(_ messageSoundName: String?) {
        defaults[UserDefaultMessageSoundName] = messageSoundName
        AVSMediaManager.sharedInstance.configureSounds()
    }
    
    func messageSoundName() -> String? {
        return defaults[UserDefaultMessageSoundName] as? String
    }
    
    func setCallSoundName(_ callSoundName: String?) {
        defaults[UserDefaultCallSoundName] = callSoundName
        AVSMediaManager.sharedInstance.configureSounds()
    }
    
    func callSoundName() -> String? {
        return defaults[UserDefaultCallSoundName] as? String
    }
    
    func setPingSoundName(_ pingSoundName: String?) {
        defaults[UserDefaultPingSoundName] = pingSoundName
        AVSMediaManager.sharedInstance.configureSounds()
    }
    
    func pingSoundName() -> String? {
        return defaults[UserDefaultPingSoundName] as? String
    }
    
    func disableSendButton() -> Bool {
        return defaults.bool(forKey: UserDefaultSendButtonDisabled)
    }
    
    func setDisableSendButton(_ disableSendButton: Bool) {
        defaults.set(disableSendButton, forKey: UserDefaultSendButtonDisabled)
        notifyDisableSendButtonChanged()
    }

    func disableCallKit() -> Bool {
        return defaults.bool(forKey: UserDefaultDisableCallKit)
    }
    
    func setDisableCallKit(_ disableCallKit: Bool) {
        defaults.set(disableCallKit, forKey: UserDefaultDisableCallKit)
        SessionManager.shared().updateCallNotificationStyleFromSettings()
    }
    
    func disableLinkPreviews() -> Bool {
        return ExtensionSettings.shared.disableLinkPreviews()
    }
    
    func setDisableLinkPreviews(_ disableLinkPreviews: Bool) {
        ExtensionSettings.shared.disableLinkPreviews() = disableLinkPreviews
        defaults.synchronize()
    }
    
    // MARK: - Features disable keys
    func enableBatchCollections() -> Bool {
        return defaults.bool(forKey: UserDefaultEnableBatchCollections)
    }
    
    func setEnableBatchCollections(_ enableBatchCollections: Bool) {
        defaults.set(enableBatchCollections, forKey: UserDefaultEnableBatchCollections)
    }
    
    // MARK: - Link opening options
    func twitterLinkOpeningOptionRawValue() -> Int {
        return defaults.integer(forKey: UserDefaultTwitterOpeningRawValue)
    }
    
    func setTwitterLinkOpeningOptionRawValue(_ twitterLinkOpeningOptionRawValue: Int) {
        defaults.set(twitterLinkOpeningOptionRawValue, forKey: UserDefaultTwitterOpeningRawValue)
    }
    
    func mapsLinkOpeningOptionRawValue() -> Int {
        return defaults.integer(forKey: UserDefaultMapsOpeningRawValue)
    }

    func setMapsLinkOpeningOptionRawValue(_ mapsLinkOpeningOptionRawValue: Int) {
        defaults.set(mapsLinkOpeningOptionRawValue, forKey: UserDefaultMapsOpeningRawValue)
    }
    
    func browserLinkOpeningOptionRawValue() -> Int {
        return defaults.integer(forKey: UserDefaultBrowserOpeningRawValue)
    }
    
    func setBrowserLinkOpeningOptionRawValue(_ browserLinkOpeningOptionRawValue: Int) {
        defaults.set(browserLinkOpeningOptionRawValue, forKey: UserDefaultBrowserOpeningRawValue)
    }
    
    func callingConstantBitRate() -> Bool {
        return defaults.bool(forKey: UserDefaultCallingConstantBitRate)
    }
    
    func setCallingConstantBitRate(_ callingConstantBitRate: Bool) {
        defaults.set(callingConstantBitRate, forKey: UserDefaultCallingConstantBitRate)
        SessionManager.shared.useConstantBitRateAudio = callingConstantBitRate
    }
    // MARK: - MediaManager
    func restoreLastUsedAVSSettings() {
        let savedIntensity = defaults[AVSMediaManagerPersistentIntensity] as? NSNumber
        var level = savedIntensity?.intValue ?? 0 as? AVSIntensityLevel
        if savedIntensity == nil {
            level = AVSIntensityLevelFull
        }
        
        AVSMediaManager.sharedInstance.intensityLevel = level
    }
    
    func storeCurrentIntensityLevelAsLastUsed() {
        let level = AVSMediaManager.sharedInstance.intensityLevel
        if level >= AVSIntensityLevelNone && level <= AVSIntensityLevelFull {
            defaults[AVSMediaManagerPersistentIntensity] = NSNumber(value: Int32(level))
        }
    }

    func restoreLastUsedAVSSettings() {
    }
    
    func storeCurrentIntensityLevelAsLastUsed() {
    }
    
    class func shared() -> Self {
    }
    
    // Persist all the settings
    func synchronize() {
    }
    
    func reset() {
    }

    // MARK: - Debug
    
/// These settings are not actually persisted, just kept in memory
    // Max audio recording duration in seconds
    var maxRecordingDurationDebug: TimeInterval = 0.0

    @objc
    func startLogging() {
        #if targetEnvironment(simulator)
        loadEnabledLogs()
        #else
        ZMSLog.startRecording(isInternal: Bundle.developerModeEnabled)
        #endif
    }
}
