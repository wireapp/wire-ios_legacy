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

extension AVAsset {

    public static func wr_convertAudioToUploadFormat(_ inPath: String, outPath: String, completion: ((_ success: Bool) -> ())? = .none) {
        let alteredAsset = AVAsset(URL: NSURL(fileURLWithPath: inPath) as URL)

        let exportSession = AVAssetExportSession(asset: alteredAsset, presetName: AVAssetExportPresetAppleM4A)!
        
        let encodedEffectAudioURL = NSURL(fileURLWithPath: outPath)
        
        exportSession.outputURL = encodedEffectAudioURL
        exportSession.outputFileType = AVFileTypeAppleM4A
        
        exportSession.exportAsynchronouslyWithCompletionHandler { [unowned exportSession] in
            switch exportSession.status {
            case .Failed:
                DDLogError("Cannot transcode \(inPath) to \(outPath): \(exportSession.error)")
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: false)
                })
            default:
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(success: true)
                })
                break
            }
            
        }
    }

}
