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
import WireSystem
import WireUtilities

private let zmLog = ZMSLog(tag: "ZMFileMetadata")

@objcMembers
open class ZMFileMetadata: NSObject {

    public let fileURL: URL
    public let thumbnail: Data?
    public let filename: String

    required public init(fileURL: URL, thumbnail: Data? = nil, name: String? = nil) {
        self.fileURL = fileURL
        self.thumbnail = thumbnail?.count > 0 ? thumbnail : nil
        let endName = name ?? (fileURL.lastPathComponent.isEmpty ? "unnamed" :  fileURL.lastPathComponent)

        self.filename = endName.removingExtremeCombiningCharacters
        super.init()
    }

    convenience public init(fileURL: URL, thumbnail: Data? = nil) {
        self.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    var asset: WireProtos.Asset {
        return WireProtos.Asset(self)
    }
}

open class ZMAudioMetadata: ZMFileMetadata {

    public let duration: TimeInterval
    public let normalizedLoudness: [Float]

    required public init(fileURL: URL, duration: TimeInterval, normalizedLoudness: [Float] = [], thumbnail: Data? = nil) {
        self.duration = duration
        self.normalizedLoudness = normalizedLoudness

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    required public init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.normalizedLoudness = []
        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }

    override var asset: WireProtos.Asset {
        return WireProtos.Asset(self)
    }

}

open class ZMVideoMetadata: ZMFileMetadata {

    public let duration: TimeInterval
    public let dimensions: CGSize

    required public init(fileURL: URL, duration: TimeInterval, dimensions: CGSize, thumbnail: Data? = nil) {
        self.duration = duration
        self.dimensions = dimensions

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: nil)
    }

    required public init(fileURL: URL, thumbnail: Data?, name: String? = nil) {
        self.duration = 0
        self.dimensions = CGSize.zero

        super.init(fileURL: fileURL, thumbnail: thumbnail, name: name)
    }

    override var asset: WireProtos.Asset {
        return WireProtos.Asset(self)
    }

}

extension ZMFileMetadata {

    var mimeType: String {
        return UTIHelper.convertToMime(fileExtension: fileURL.pathExtension) ?? "application/octet-stream"
    }

    var size: UInt64 {
        do {
            let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            let size = attributes.fileSize ?? 0
            return UInt64(size)
        } catch {
            zmLog.error("Couldn't read file size of \(fileURL)")
            return 0
        }
    }

}
