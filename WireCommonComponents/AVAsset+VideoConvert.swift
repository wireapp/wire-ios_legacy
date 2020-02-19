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
import WireUtilities

private let zmLog = ZMSLog(tag: "UI")

extension AVAsset {
    
    public static func convertAudioToUploadFormat(_ inPath: String, outPath: String, completion: ((_ success: Bool) -> ())? = .none) {
        
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
    
    public static func convertVideoToUploadFormat(at url: URL,
                                                  deleteSourceFile: Bool = true
                                                  completion: @escaping (URL?, AVAsset?, Error?) -> Void) {
        let filename = URL(fileURLWithPath: URL(fileURLWithPath: url.lastPathComponent ).deletingPathExtension().absoluteString).appendingPathExtension("mp4").absoluteString
        let asset: AVURLAsset = AVURLAsset(url: url, options: nil) ///TODO: "file:/video.mp4"
        
        asset.convert(completion: { URL, asset, error in
            
            completion(URL, asset, error)
            
            if deleteSourceFile {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let deleteError {
                    zmLog.error("Cannot delete file: \(url) (\(deleteError))")
                }
            }
            
        }, filename: filename)
    }
    
    public func convert(completion: @escaping (URL?, AVAsset?, Error?) -> Void,
                        filename: String) {
        let tmpfile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename).absoluteString
        
        let outputURL = URL(fileURLWithPath: tmpfile)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch let deleteError {
                zmLog.error("Cannot delete old leftover at \(outputURL): \(deleteError)")
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = .mp4
        exportSession.metadata = []
        exportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()
        
        weak var session: AVAssetExportSession? = exportSession
        exportSession.exportAsynchronously(completionHandler: {
            if let session = session,
                let error = session.error {
                zmLog.error("Export session error: status=\(session.status.rawValue) error=\(error) output=\(outputURL)")
            }
            
            DispatchQueue.main.async(execute: {
                completion(outputURL, self, session?.error)
            })
        })
    }
    
}
