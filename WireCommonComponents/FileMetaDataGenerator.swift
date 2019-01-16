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
import MobileCoreServices
import WireDataModel
import AVFoundation

private let zmLog = ZMSLog(tag: "UI")

@objcMembers public final class FileMetaDataGenerator: NSObject {

    @objc static public func metadataForFileAtURL(_ url: URL, UTI uti: String, name: String, completion: @escaping (ZMFileMetadata) -> ()) {
        SharedPreviewGenerator.generator.generatePreview(url, UTI: uti) { (preview) in
            let thumbnail = preview != nil ? preview!.jpegData(compressionQuality: 0.9) : nil
            
            if AVURLAsset.wr_isAudioVisualUTI(uti) {
                let asset = AVURLAsset(url: url)
                
                if let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
                    completion(ZMVideoMetadata(fileURL: url, duration: asset.duration.seconds, dimensions: videoTrack.naturalSize, thumbnail: thumbnail))
                } else {
                    let loudness = audioSamplesFromAsset(asset, maxSamples: 100)
                    
                    completion(ZMAudioMetadata(fileURL: url, duration: asset.duration.seconds, normalizedLoudness: loudness ?? []))
                }
            } else {
                // TODO: set the name of the file (currently there's no API, it always gets it from the URL)
                completion(ZMFileMetadata(fileURL: url, thumbnail: thumbnail))
            }
        }
    }
    
}

extension AVURLAsset {
    @objc static func wr_isAudioVisualUTI(_ UTI: String) -> Bool {
        return audiovisualTypes().reduce(false) { (conformsBefore, compatibleUTI) -> Bool in
            conformsBefore || UTTypeConformsTo(UTI as CFString, compatibleUTI as CFString)
        }
    }
}

func audioSamplesFromAsset(_ asset: AVAsset, maxSamples: UInt64) -> [Float]? {
    let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first
    let reader: AVAssetReader
    do {
        reader = try AVAssetReader(asset: asset)
    }
    catch let error {
        zmLog.error("Cannot read asset metadata for \(asset): \(error)")
        return .none
    }
    
    let outputSettings = [ AVFormatIDKey : NSNumber(value: kAudioFormatLinearPCM),
                           AVLinearPCMBitDepthKey : 16,
                           AVLinearPCMIsBigEndianKey : false,
                           AVLinearPCMIsFloatKey : false,
                           AVLinearPCMIsNonInterleaved : false ]
    
    let output = AVAssetReaderTrackOutput(track: assetTrack!, outputSettings: outputSettings)
    output.alwaysCopiesSampleData = false
    reader.add(output)
    var sampleCount : UInt64 = 0
    
    for item in (assetTrack?.formatDescriptions)! {
        let formatDescription  = item as! CMFormatDescription
        let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        sampleCount = UInt64((basicDescription?.pointee.mSampleRate ?? 0) * Float64(asset.duration.value)/Float64(asset.duration.timescale))
    }
    
    let stride = Int(max(sampleCount / maxSamples, 1))
    var sampleData : [Float] = []
    var sampleSkipCounter = 0
    
    reader.startReading()
    
    while (reader.status == .reading) {
        if let sampleBuffer = output.copyNextSampleBuffer() {
            var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil))
            var buffer : CMBlockBuffer?
            var bufferSize = 0
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: &bufferSize, bufferListOut: nil, bufferListSize: 0, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: nil)
            
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                    bufferListSizeNeededOut: nil,
                                                                    bufferListOut: &audioBufferList,
                                                                    bufferListSize: bufferSize,
                                                                    blockBufferAllocator: nil,
                                                                    blockBufferMemoryAllocator: nil,
                                                                    flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                    blockBufferOut: &buffer)
            
            let abl = UnsafeMutableAudioBufferListPointer(&audioBufferList)
            var maxAmplitude : Int16 = 0
            
            for buffer in abl {
                guard let data = buffer.mData else {
                    continue
                }
                
                let i16bufptr = UnsafeBufferPointer(start: data.assumingMemoryBound(to: Int16.self), count: Int(buffer.mDataByteSize)/Int(MemoryLayout<Int16>.size))
                
                for sample in Array(i16bufptr) {
                    sampleSkipCounter += 1
                    maxAmplitude = max(maxAmplitude, sample)
                    
                    if sampleSkipCounter == stride {
                        sampleData.append(Float(scalar(maxAmplitude)))
                        sampleSkipCounter = 0
                        maxAmplitude = 0
                    }
                }
            }
            CMSampleBufferInvalidate(sampleBuffer)
        }
    }
    
    return sampleData
}
