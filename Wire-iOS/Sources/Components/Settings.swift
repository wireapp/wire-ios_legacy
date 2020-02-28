
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

extension Notification.Name {
    static let SettingsColorSchemeChanged = Notification.Name("SettingsColorSchemeChanged")
}

enum SettingKey: String, CaseIterable {
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
    case blackListDownloadInterval = "ZMBlacklistDownloadInterval"
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
    subscript<T>(index: SettingKey) -> T? {
        get {
            return defaults.value(forKey: index.rawValue) as? T
        }
        set {
            defaults.set(newValue, forKey: index.rawValue) ///TODO: raw value of SettingsLastScreen
//            defaults.synchronize()
            
            ///TODO: side effect
        }
    }

    subscript<E: RawRepresentable>(index: SettingKey) -> E? {
        get {
            let value = defaults.value(forKey: index.rawValue)
            return value as? E ///TODO: need rawValue: ?
        }
        set {
            defaults.set(newValue?.rawValue, forKey: index.rawValue)
//            defaults.synchronize()
            
            ///TODO: side effect
        }
    }

//    var chatHeadsDisabled: Bool {
//        get {
//            return defaults.bool(forKey: UserDefaultChatHeadsDisabled)
//        }
//
//        set {
//            defaults.set(newValue, forKey: UserDefaultChatHeadsDisabled)
//            defaults.synchronize()
//        }
//    }
//
//    var disableMarkdown: Bool {
//        get {
//            return defaults.bool(forKey: UserDefaultDisableMarkdown)
//        }
//
//        set {
//            defaults.set(newValue, forKey: UserDefaultDisableMarkdown)
//            defaults.synchronize()
//        }
//    }
    
    var shouldRegisterForVoIPNotificationsOnly = false
    var disableSendButton = false
    var disableLinkPreviews = false
    var disableCallKit = false
    var callingConstantBitRate = false
    var enableBatchCollections = false
    /* develop option */
//    var lastViewedScreen: SettingsLastScreen {
//        get {
//            return SettingsLastScreen(rawValue: defaults.integer(forKey: UserDefaultLastViewedScreen)) ?? .none
//        }
//
//        set {
//            defaults.set(newValue.rawValue, forKey: UserDefaultLastViewedScreen)
//            defaults.synchronize()
//        }
//    }

//    var preferredCamera: SettingsCamera {
//        get {
//            return SettingsCamera(rawValue: defaults.integer(forKey: UserDefaultPreferredCamera)) ?? .front
//        }
//
//        set {
//            defaults.set(newValue.rawValue, forKey: UserDefaultPreferredCamera)
//        }
//    }

    var blacklistDownloadInterval: TimeInterval {
        let HOURS_6 = 6 * 60 * 60
        let settingValue = defaults.integer(forKey: SettingKey.blackListDownloadInterval.rawValue)
        return TimeInterval(settingValue > 0 ? settingValue : HOURS_6)
    }
    
//    var lastUserLocation: LocationData? {
//        get {
//            guard let locationDict = defaults.dictionary(forKey: UserDefaultLastUserLocation) else { return nil }
//            return LocationData.locationData(fromDictionary: locationDict)
//        }
//
//        set {
//            let locationDict = newValue.toDictionary
//            defaults.setValue(locationDict, forKey: UserDefaultLastUserLocation)
//        }
//    }

    var messageSoundName: String?
    var callSoundName: String?
    var pingSoundName: String?
    var twitterLinkOpeningOptionRawValue = 0
    var browserLinkOpeningOptionRawValue = 0
    var mapsLinkOpeningOptionRawValue = 0
    
    
//    var lastPushAlertDate: Date? {
//        get {
//            return defaults.value(forKey: UserDefaultLastPushAlertDate) as? Date
//        }
//
//        set {
//            defaults.setValue(newValue, forKey: UserDefaultLastPushAlertDate)
//            defaults.synchronize()
//        }
//    }
    
    
    

    
    /// These settings are not actually persisted, just kept in memory
    // Max audio recording duration in seconds
    var maxRecordingDurationDebug: TimeInterval = 0.0

    static var shared: Settings = Settings()
    
    override init() {
        super.init()
        migrateAppCenterAndOptOutSettingsToSharedDefaults()
        restoreLastUsedAVSSettings()
        
        startLogging()
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func migrateAppCenterAndOptOutSettingsToSharedDefaults() {
        if !defaults.bool(forKey: SettingKey.didMigrateHockeySettingInitially.rawValue) {
            ExtensionSettings.shared.disableLinkPreviews = disableLinkPreviews
            defaults.set(true, forKey: SettingKey.didMigrateHockeySettingInitially.rawValue)
        }
    }
    
    // Persist all the settings
    func synchronize() {
        storeCurrentIntensityLevelAsLastUsed()
        
        defaults.synchronize()
    }
    
    func reset() {
        for key in SettingKey.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
        UserDefaults.standard.synchronize()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        synchronize()
    }
    
//    func shouldRegisterForVoIPNotificationsOnly() -> Bool {
//        return defaults.bool(forKey: SettingKey.VoIPNotificationsOnly)
//    }
//
//    func setShouldRegisterForVoIPNotificationsOnly(_ shoudlRegisterForVoIPOnly: Bool) {
//        defaults.set(shoudlRegisterForVoIPOnly, forKey: SettingKey.VoIPNotificationsOnly)
//        defaults.synchronize()
//    }
    
//    func setMessageSoundName(_ messageSoundName: String?) {
//        defaults[UserDefaultMessageSoundName] = messageSoundName
    //        AVSMediaManager.sharedInstance.configureSounds() ///TODO:
//    }
//
//    func messageSoundName() -> String? {
//        return defaults[UserDefaultMessageSoundName] as? String
//    }
//
//    func setCallSoundName(_ callSoundName: String?) {
//        defaults[UserDefaultCallSoundName] = callSoundName
//        AVSMediaManager.sharedInstance.configureSounds() TODO:
//    }
//
//    func callSoundName() -> String? {
//        return defaults[UserDefaultCallSoundName] as? String
//    }
    
//    func setPingSoundName(_ pingSoundName: String?) {
//        defaults[UserDefaultPingSoundName] = pingSoundName
//        AVSMediaManager.sharedInstance.configureSounds()
//        //TODO:
//    }
//
//    func pingSoundName() -> String? {
//        return defaults[UserDefaultPingSoundName] as? String
//    }
    
//    func disableSendButton() -> Bool {
//        return defaults.bool(forKey: UserDefaultSendButtonDisabled)
//    }
//
//    func setDisableSendButton(_ disableSendButton: Bool) {
//        defaults.set(disableSendButton, forKey: UserDefaultSendButtonDisabled)
//        notifyDisableSendButtonChanged() ///TODO:
//    }

//    func disableCallKit() -> Bool {
//        return defaults.bool(forKey: UserDefaultDisableCallKit)
//    }
//
//    func setDisableCallKit(_ disableCallKit: Bool) {
//        defaults.set(disableCallKit, forKey: UserDefaultDisableCallKit)
//        ///TODO
//        SessionManager.shared().updateCallNotificationStyleFromSettings()
//    }
    
//    func disableLinkPreviews() -> Bool {
//        return ExtensionSettings.shared.disableLinkPreviews()
//    }
//
//    func setDisableLinkPreviews(_ disableLinkPreviews: Bool) {
//        ExtensionSettings.shared.disableLinkPreviews() = disableLinkPreviews
//        defaults.synchronize()
//    }
//
//    // MARK: - Features disable keys
//    func enableBatchCollections() -> Bool {
//        return defaults.bool(forKey: UserDefaultEnableBatchCollections)
//    }
//
//    func setEnableBatchCollections(_ enableBatchCollections: Bool) {
//        defaults.set(enableBatchCollections, forKey: UserDefaultEnableBatchCollections)
//    }
    
    // MARK: - Link opening options
//    func twitterLinkOpeningOptionRawValue() -> Int {
//        return defaults.integer(forKey: UserDefaultTwitterOpeningRawValue)
//    }
//
//    func setTwitterLinkOpeningOptionRawValue(_ twitterLinkOpeningOptionRawValue: Int) {
//        defaults.set(twitterLinkOpeningOptionRawValue, forKey: UserDefaultTwitterOpeningRawValue)
//    }
//
//    func mapsLinkOpeningOptionRawValue() -> Int {
//        return defaults.integer(forKey: UserDefaultMapsOpeningRawValue)
//    }
//
//    func setMapsLinkOpeningOptionRawValue(_ mapsLinkOpeningOptionRawValue: Int) {
//        defaults.set(mapsLinkOpeningOptionRawValue, forKey: UserDefaultMapsOpeningRawValue)
//    }
//
//    func browserLinkOpeningOptionRawValue() -> Int {
//        return defaults.integer(forKey: UserDefaultBrowserOpeningRawValue)
//    }
//
//    func setBrowserLinkOpeningOptionRawValue(_ browserLinkOpeningOptionRawValue: Int) {
//        defaults.set(browserLinkOpeningOptionRawValue, forKey: UserDefaultBrowserOpeningRawValue)
//    }
    
//    func callingConstantBitRate() -> Bool {
//        return defaults.bool(forKey: UserDefaultCallingConstantBitRate)
//    }
//
//    func setCallingConstantBitRate(_ callingConstantBitRate: Bool) {
//        defaults.set(callingConstantBitRate, forKey: UserDefaultCallingConstantBitRate)
    // TODO:
//        SessionManager.shared.useConstantBitRateAudio = callingConstantBitRate
//    }
    // MARK: - MediaManager
    func restoreLastUsedAVSSettings() {
        if let savedIntensity = defaults.object(forKey: SettingKey.avsMediaManagerPersistentIntensity.rawValue) as? NSNumber,
            let intensityLevel = AVSIntensityLevel(rawValue: UInt(savedIntensity.intValue)){
            AVSMediaManager.sharedInstance().intensityLevel = intensityLevel
        } else {
            AVSMediaManager.sharedInstance().intensityLevel = .full
        }
    }
    
    func storeCurrentIntensityLevelAsLastUsed() {
        let level = AVSMediaManager.sharedInstance().intensityLevel.rawValue
        if level >= AVSIntensityLevel.none.rawValue && level <= AVSIntensityLevel.full.rawValue {
            defaults.setValue(NSNumber(value: level), forKey: SettingKey.avsMediaManagerPersistentIntensity.rawValue)
        }
    }

    
    // MARK: - Debug
    

    private func startLogging() {
        #if targetEnvironment(simulator)
        loadEnabledLogs()
        #else
        ZMSLog.startRecording(isInternal: Bundle.developerModeEnabled)
        #endif
    }
}
