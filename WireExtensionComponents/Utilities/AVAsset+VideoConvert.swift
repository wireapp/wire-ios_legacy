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
import AVFoundation

private let zmLog = ZMSLog(tag: "UI")

extension AVAsset {

    @objc public static func wr_convertAudioToUploadFormat(_ inPath: String, outPath: String, completion: ((_ success: Bool) -> ())? = .none) {

        let fileURL = URL(fileURLWithPath: inPath)
        let alteredAsset = AVAsset(url: fileURL)
        let session = AVAssetExportSession(asset: alteredAsset, presetName: AVAssetExportPresetAppleM4A)
        
        guard let exportSession = session else {
            zmLog.error("Failed to create export session with asset \(alteredAsset)")
            completion?(false)
            return
        }
    
        let encodedEffectAudioURL = URL(fileURLWithPath: outPath)
        
        exportSession.outputURL = encodedEffectAudioURL as URL
        exportSession.outputFileType = AVFileType.m4a
        
        exportSession.exportAsynchronously { [unowned exportSession] in
            switch exportSession.status {
            case .failed:
                zmLog.error("Cannot transcode \(inPath) to \(outPath): \(String(describing: exportSession.error))")
                DispatchQueue.main.async {
                    completion?(false)
                }
            default:
                DispatchQueue.main.async {
                    completion?(true)
                }
                break
            }
            
        }
    }

}
