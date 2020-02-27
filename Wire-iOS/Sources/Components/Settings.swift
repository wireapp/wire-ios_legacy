
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

let SettingsColorSchemeChangedNotification = "SettingsColorSchemeChangedNotification"

extension Notification.Name {
    static let SettingsColorSchemeChanged = Notification.Name("SettingsColorSchemeChanged")
}

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

enum SettingKey: String {
    // NB!!! After adding the key here please make sure to add it to @m +allDefaultsKeys as well
    case disableMarkdown = "UserDefaultDisableMarkdown"
    case chatHeadsDisabled = "ZDevOptionChatHeadsDisabled"
    case lastPushAlertDate = "LastPushAlertDate"
    case voIPNotificationsOnly = "VoIPNotificationsOnly"
    case lastViewedConversation = "LastViewedConversation"
    case colorScheme = "ColorScheme"
    case lastViewedScreen = "LastViewedScreen"
    case preferredCameraFlashMode = "PreferredCameraFlashMode"
    case preferredCamera = "PreferredCamera"
    case avsMediaManagerPersistentIntensity = "AVSMediaManagerPersistentIntensity"
    case lastUserLocation = "LastUserLocation"
    case blackListDownloadIntervalKey = "ZMBlacklistDownloadInterval"
    case messageSoundName = "ZMMessageSoundName"
    case callSoundName = "ZMCallSoundName"
    case pingSoundName = "ZMPingSoundName"
    case sendButtonDisabled = "SendButtonDisabled"
    case disableCallKit = "UserDefaultDisableCallKit"
    case enableBatchCollections = "UserDefaultEnableBatchCollections"
    case callingProtocolStrategy = "CallingProtocolStrategy"
    case twitterOpeningRawValue = "TwitterOpeningRawValue"
    case mapsOpeningRawValue = "MapsOpeningRawValue"
    case browserOpeningRawValue = "BrowserOpeningRawValue"
    case didMigrateHockeySettingInitially = "DidMigrateHockeySettingInitially"
    case callingConstantBitRate = "CallingConstantBitRate"
    case disableLinkPreviews = "DisableLinkPreviews"
}


/// Model object for locally stored (not in SE or AVS) user app settings
///TODO: no nsobject?
final class Settings: NSObject {
    subscript(index: SettingKey) -> Any {
        get {
            return defaults.bool(forKey: index)
        }
        set(newValue) {
            defaults.set(newValue, forKey: UserDefaultChatHeadsDisabled)
            defaults.synchronize()
        }
    }

    var chatHeadsDisabled: Bool {
        get {
            return defaults.bool(forKey: UserDefaultChatHeadsDisabled)
        }
        
        set {
            defaults.set(newValue, forKey: UserDefaultChatHeadsDisabled)
            defaults.synchronize()
        }
    }
    
    var disableMarkdown: Bool {
        get {
            return defaults.bool(forKey: UserDefaultDisableMarkdown)
        }
        
        set {
            defaults.set(newValue, forKey: UserDefaultDisableMarkdown)
            defaults.synchronize()
        }
    }
    
    var shouldRegisterForVoIPNotificationsOnly = false
    var disableSendButton = false
    var disableLinkPreviews = false
    var disableCallKit = false
    var callingConstantBitRate = false
    var enableBatchCollections = false
    /* develop option */
    var lastViewedScreen: SettingsLastScreen {
        get {
            return SettingsLastScreen(rawValue: defaults.integer(forKey: UserDefaultLastViewedScreen)) ?? .none
        }
        
        set {
            defaults.set(newValue.rawValue, forKey: UserDefaultLastViewedScreen)
            defaults.synchronize()
        }
    }

    var preferredCamera: SettingsCamera {
        get {
            return SettingsCamera(rawValue: defaults.integer(forKey: UserDefaultPreferredCamera)) ?? .front
        }
        
        set {
            defaults.set(newValue.rawValue, forKey: UserDefaultPreferredCamera)
        }
    }

    var blacklistDownloadInterval: TimeInterval {
        let HOURS_6 = 6 * 60 * 60
        let settingValue = defaults.integer(forKey: BlackListDownloadIntervalKey)
        return TimeInterval(settingValue > 0 ? settingValue : HOURS_6)
    }
    
    var lastUserLocation: LocationData? {
        get {
            guard let locationDict = defaults.dictionary(forKey: UserDefaultLastUserLocation) else { return nil }
            return LocationData.locationData(fromDictionary: locationDict)
        }
        
        set {
            let locationDict = newValue.toDictionary
            defaults.setValue(locationDict, forKey: UserDefaultLastUserLocation)
        }
    }

    var messageSoundName: String?
    var callSoundName: String?
    var pingSoundName: String?
    var twitterLinkOpeningOptionRawValue = 0
    var browserLinkOpeningOptionRawValue = 0
    var mapsLinkOpeningOptionRawValue = 0
    
    
    var lastPushAlertDate: Date? {
        get {
            return defaults.value(forKey: UserDefaultLastPushAlertDate) as? Date
        }
        
        set {
            defaults.setValue(newValue, forKey: UserDefaultLastPushAlertDate)
            defaults.synchronize()
        }
    }
    
    
    

    
    private var maxRecordingDurationDebug: TimeInterval = 0.0

    static var allDefaultsKeys: [String] = [
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
    
    static var shared: Settings = Settings()
    
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
    
    func synchronize() {
        storeCurrentIntensityLevelAsLastUsed()
        
        defaults.synchronize()
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
