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

// MARK: - audio convert

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
}

// MARK: - video convert

public typealias ConvertVideoCompletion = (URL?, AVURLAsset?, Error?) -> Void

extension AVURLAsset {
    
    public static let defaultVideoQuality: String = AVAssetExportPresetHighestQuality
    
    /// Convert a Video file URL to a upload format
    ///
    /// - Parameters:
    ///   - url: video file URL
    ///   - quality: video quality, default is AVAssetExportPresetHighestQuality
    ///   - deleteSourceFile: set to false for testing only
    ///   - completion: ConvertVideoCompletion closure. URL: exported file's URL. AVURLAsset: assert of converted video. Error: error of conversion
    public static func convertVideoToUploadFormat(at url: URL,
                                                  quality: String = AVURLAsset.defaultVideoQuality,
                                                  deleteSourceFile: Bool = true,
                                                  fileLengthLimit: Int64? = nil,
                                                  completion: @escaping ConvertVideoCompletion ) {
        let filename = url.deletingPathExtension().lastPathComponent + ".mp4"
        let asset: AVURLAsset = AVURLAsset(url: url, options: nil)
        
        guard let track = AVAsset(url: url as URL).tracks(withMediaType: AVMediaType.video).first else { return }
        let size = track.naturalSize

        
        let cappedQuality: String
        
        if size.width > 1920 || size.height > 1920 {
            cappedQuality = AVAssetExportPreset1920x1080
        } else {
            cappedQuality = quality
        }
        
        asset.convert(filename: filename,
                      quality: cappedQuality, fileLengthLimit: fileLengthLimit) { URL, asset, error in
            
            completion(URL, asset, error)
            
            if deleteSourceFile {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let deleteError {
                    zmLog.error("Cannot delete file: \(url) (\(deleteError))")
                }
            }
        }
    }

    public func convert(filename: String,
                        quality: String = defaultVideoQuality,
                        fileLengthLimit: Int64? = nil,
                        completion: @escaping ConvertVideoCompletion) {
        
        let outputURL: URL
        do {
            try outputURL = FileManager.createTmpDirectory(fileName: filename)
        } catch let error {
            zmLog.error("Cannot createTmpDirectory with filename: \(filename). error: \(error)")
            
            return
        }

        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch let deleteError {
                zmLog.error("Cannot delete old leftover at \(outputURL): \(deleteError)")
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: quality) else { return }
        
        if let fileLengthLimit = fileLengthLimit {
            exportSession.fileLengthLimit = fileLengthLimit
        }
        
        exportSession.exportVideo(exportURL: outputURL) { url, error in
            DispatchQueue.main.async(execute: {
                completion(outputURL, self, error)
            })
        }
    }
}

extension AVAssetExportSession {
    public func exportVideo(exportURL: URL,
                            completion: @escaping (URL?, Error?) -> Void) {
        if FileManager.default.fileExists(atPath: exportURL.path) {
            do {
                try FileManager.default.removeItem(at: exportURL)
            }
            catch let error {
                zmLog.error("Cannot delete old leftover at \(exportURL): \(error)")
            }
        }
        
        outputURL = exportURL
        shouldOptimizeForNetworkUse = true
        outputFileType = .mp4
        metadata = []
        metadataItemFilter = AVMetadataItemFilter.forSharing()
        
        weak var session: AVAssetExportSession? = self
        exportAsynchronously() {
            if let session = session,
                let error = session.error {
                zmLog.error("Export session error: status=\(session.status.rawValue) error=\(error) output=\(exportURL)")
            }
            
            completion(exportURL, session?.error)
        }
    }
}
