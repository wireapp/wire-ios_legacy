//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import AudioToolbox

public enum ZMSound: String, CustomStringConvertible {
    case None       = "silence"
    case Bell       = "bell"
    case Calipso    = "calipso"
    case Chime      = "chime"
    case Circles    = "circles"
    case Glass      = "glass"
    case Hello      = "hello"
    case Input      = "input"
    case Keys       = "keys"
    case Note       = "note"
    case Popcorn    = "popcorn"
    case Synth      = "synth"
    case Telegraph  = "telegraph"
    case TriTone    = "tri-tone"
    case Harp       = "harp"
    case Marimba    = "marimba"
    case OldPhone   = "old-phone"
    case Opening    = "opening"
    case WireCall   = "ringing_from_them"
    case WirePing   = "ping_from_them"
    case WireText   = "new_message"

    public static let soundEffects = [
        Bell,
        Calipso,
        Chime,
        Circles,
        Glass,
        Hello,
        Input,
        Keys,
        Note,
        Popcorn,
        Synth,
        Telegraph,
        TriTone]

    public static let ringtones = [
        Harp,
        Marimba,
        OldPhone,
        Opening]

    public func isRingtone() -> Bool {
        return type(of: self).ringtones.contains(self)
    }

    fileprivate static var playingPreviewID: SystemSoundID?
    fileprivate static var playingPreviewURL: URL?

    fileprivate static func stopPlayingPreview() {
        if self.playingPreviewURL != nil,
            let soundId = self.playingPreviewID {
            AudioServicesDisposeSystemSoundID(soundId)
            self.playingPreviewID = .none
            self.playingPreviewURL = .none
        }
    }

    public static func playPreviewForURL(_ mediaURL: URL) {
        self.stopPlayingPreview()

        self.playingPreviewURL = mediaURL
        var soundId: SystemSoundID = 0

        if AudioServicesCreateSystemSoundID(mediaURL as CFURL, &soundId) == kAudioServicesNoError {
            self.playingPreviewID = soundId
        }

        AudioServicesPlaySystemSound(soundId)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(4 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
            if self.playingPreviewID == soundId {
                self.stopPlayingPreview()
            }
        }
    }

    public func fileURL() -> URL? {
        switch self {
        case .None:
            return nil
        case .WireText, .WirePing, .WireCall:
            guard let path = Bundle.main.path(forResource: self.rawValue, ofType: type(of: self).fileExtension, inDirectory: "audio-notifications") else {
                return nil
            }
            return URL(fileURLWithPath: path)
        default:
            guard let path = Bundle.main.path(forResource: self.rawValue, ofType: type(of: self).fileExtension) else {
                return nil
            }
            return URL(fileURLWithPath: path)
        }
    }

    fileprivate static let fileExtension = "m4a"

    public func filename() -> String {
        return (self.rawValue as NSString).appendingPathExtension(type(of: self).fileExtension)!
    }

    public var description: String {
        return self.rawValue.capitalized
    }

    public var descriptionLocalizationKey: String {
        switch self {
        case .None:
            return "self.settings.sound_menu.sounds.none"
        case .WireCall:
            return "self.settings.sound_menu.sounds.wire_call"
        case .WireText:
            return "self.settings.sound_menu.sounds.wire_message"
        case .WirePing:
            return "self.settings.sound_menu.sounds.wire_ping"
        default:
            return self.rawValue.capitalized
        }
    }

    public func playPreview() {
        if let soundFileURL = fileURL() {
            type(of: self).playPreviewForURL(soundFileURL)
        } else {
            type(of: self).stopPlayingPreview()
        }
    }
}
