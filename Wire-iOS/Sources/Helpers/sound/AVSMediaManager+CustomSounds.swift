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


import Foundation
import avs
import WireSystem
import WireSyncEngine
import WireCommonComponents

enum MediaManagerSound: String {
    case outgoingKnockSound = "ping_from_me"
    case incomingKnockSound = "ping_from_them"
    case messageReceivedSound = "new_message"
    case firstMessageReceivedSound = "first_message"
    case someoneJoinsVoiceChannelSound = "talk"
    case transferVoiceToHereSound = "pull_voice"
    case ringingFromThemSound = "ringing_from_them"
    case ringingFromThemInCallSound = "ringing_from_them_incall"
    case callDropped = "call_drop"
    case alert = "alert"
    case camera = "camera"
    case someoneLeavesVoiceChannelSound = "talk_later"
}


private let zmLog = ZMSLog(tag: "AVSMediaManager CustomSounds")

extension AVSMediaManager {
    static private var MediaManagerSoundConfig: [AnyHashable: Any]? = nil

    func play(sound: MediaManagerSound) {
        playSound(sound.rawValue)
    }

    func stop(sound: MediaManagerSound) {
        stopSound(sound.rawValue)
    }

    func playKnockSound() {
        play(sound: .outgoingKnockSound)
    }

    func mediaManagerPlayAlert() {
        playSound(MediaManagerSound.alert.rawValue)
    }

    private func configureDefaultSounds() {
        guard let mediaManager = AVSMediaManager.sharedInstance() else { return }

        let audioDir = "audio-notifications"

        if AVSMediaManager.MediaManagerSoundConfig == nil,
           let path = Bundle.main.path(forResource: "MediaManagerConfig", ofType: "plist", inDirectory: audioDir) {

            let soundConfig = NSDictionary(contentsOfFile: path) as? [AnyHashable: Any]

            if soundConfig == nil {
                zmLog.error("Couldn't load sound config file: \(path)")
                return
            }

            AVSMediaManager.MediaManagerSoundConfig = soundConfig
        }


        // Unregister all previous custom sounds
        let sounds: [MediaManagerSound] = [.firstMessageReceivedSound,
                                           .messageReceivedSound,
                                           .ringingFromThemInCallSound,
                                           .ringingFromThemSound,
                                           .outgoingKnockSound,
                                           .incomingKnockSound]
        sounds.forEach() {
            mediaManager.unregisterMedia(byName: $0.rawValue)
        }

        mediaManager.registerMedia(fromConfiguration: AVSMediaManager.MediaManagerSoundConfig, inDirectory: audioDir)
    }

    func configureSounds() {
        configureDefaultSounds()
        configureCustomSounds()
    }

    func observeSoundConfigurationChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.messageSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.callSoundName.changeNotificationName), object: .none)
        NotificationCenter.default.addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: NSNotification.Name(rawValue: SettingsPropertyName.pingSoundName.changeNotificationName), object: .none)
    }

    private func configureCustomSounds() {
        let settingsPropertyFactory = SettingsPropertyFactory(userSession: nil, selfUser: nil)

        let messageSoundProperty = settingsPropertyFactory.property(.messageSoundName)
        self.updateCustomSoundForProperty(messageSoundProperty)

        let callSoundProperty = settingsPropertyFactory.property(.callSoundName)
        self.updateCustomSoundForProperty(callSoundProperty)

        let pingSoundProperty = settingsPropertyFactory.property(.pingSoundName)
        self.updateCustomSoundForProperty(pingSoundProperty)
    }

    func updateCustomSoundForProperty(_ property: SettingsProperty) {
        let name = property.propertyName.rawValue
        let value = property.rawValue()
        if let stringValue = value as? String {
            updateCustomSoundForName(name, propertyValue: stringValue)
        }
    }

    func updateCustomSoundForName(_ propertyName: String, propertyValue: String?) {
        let value = propertyValue

        let soundValue = value == .none ? .none : ZMSound(rawValue: value!)

        switch propertyName {
        case SettingsPropertyName.messageSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.firstMessageReceivedSound.rawValue)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.messageReceivedSound.rawValue)

        case SettingsPropertyName.callSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.ringingFromThemInCallSound.rawValue)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.ringingFromThemSound.rawValue)

        case SettingsPropertyName.pingSoundName.rawValue:
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.outgoingKnockSound.rawValue)
            self.register(soundValue?.fileURL(), forMedia: MediaManagerSound.incomingKnockSound.rawValue)

        default:
            fatalError("\(propertyName) is not a sound property")
        }
    }

    // MARK: - Notifications
    @objc func didUpdateSound(_ notification: NSNotification?) {
        self.configureSounds()

        if notification?.name.rawValue == SettingsPropertyName.callSoundName.changeNotificationName {
            SessionManager.shared?.updateCallKitConfiguration()
        }
    }
}
