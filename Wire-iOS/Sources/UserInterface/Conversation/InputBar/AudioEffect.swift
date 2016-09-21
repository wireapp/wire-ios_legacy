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
import CocoaLumberjackSwift


extension String {
    @discardableResult public func deleteFileAtPath() -> Bool {
        do {
            try FileManager.default.removeItem(atPath: self)
        }
        catch (let error) {
            DDLogError("Cannot delete file: \(self): \(error)")
            return false
        }
        return true
    }
}

extension AVSAudioEffectType: CustomStringConvertible {

    public var icon: ZetaIconType {
        get {
            switch self {
            case .None:
                return .Person
            case .PitchupInsane:
                return .EffectBallon // Helium
            case .PitchdownInsane:
                return .EffectJellyfish // Jellyfish
            case .PaceupMed:
                return .EffectRabbit // Hare
            case .ReverbMax:
                return .EffectChurch // Cathedral
            case .ChorusMax:
                return .EffectAlien // Alien
            case .VocoderMed:
                return .EffectRobot // Robot
            case .Reverse:
                return .EffectReverse // UpsideDown
            default:
                return .ExclamationMark
            }
        }
    }
    
    public var description: String {
        get {
            switch self {
            case .ChorusMin:
                return "ChorusMin"
            case .ChorusMax:
                return "Alien"
            case .ReverbMin:
                return "ReverbMin"
            case .ReverbMed:
                return "ReverbMed"
            case .ReverbMax:
                return "Cathedral"
            case .PitchupMin:
                return "PitchupMin"
            case .PitchupMed:
                return "PitchupMed"
            case .PitchupMax:
                return "PitchupMax"
            case .PitchupInsane:
                return "Helium"
            case .PitchdownMin:
                return "PitchdownMin"
            case .PitchdownMed:
                return "PitchdownMed"
            case .PitchdownMax:
                return "PitchdownMax"
            case .PitchdownInsane:
                return "Jellyfish"
            case .PaceupMin:
                return "PaceupMin"
            case .PaceupMed:
                return "Hare"
            case .PaceupMax:
                return "PaceupMax"
            case .PacedownMin:
                return "PacedownMin"
            case .PacedownMed:
                return "PacedownMed"
            case .PacedownMax:
                return "Turtle"
            case .Reverse:
                return "UpsideDown"
            case .VocoderMed:
                return "VocoderMed"
            case .None:
                return "None"
            default:
                return "Unknown"
            }
        }
    }
    
    public static let displayedEffects: [AVSAudioEffectType] = [.None,
                                                                .PitchupInsane,
                                                                .PitchdownInsane,
                                                                .PaceupMed,
                                                                .ReverbMax,
                                                                .ChorusMax,
                                                                .VocoderMed,
                                                                .Reverse]
    
    public func apply(_ inPath: String, outPath: String, completion: (() -> ())? = .none) {
        
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var convertQueue: dispatch_queue_t? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.convertQueue = dispatch_queue_create("audioEffectQueue", DISPATCH_QUEUE_SERIAL)
        }
        
        dispatch_async(Static.convertQueue!) {
            
            let result = AVSAudioEffect().applyEffectWav(nil, inFile: inPath, outFile: outPath, effect: self, nr_flag: true)
            DDLogInfo("applyEffect \(self) from \(inPath) to \(outPath): \(result)")
            dispatch_async(dispatch_get_main_queue(), {                 
                completion?()
            })
        }
    }
}
