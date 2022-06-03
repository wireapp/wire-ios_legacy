//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import UIKit

/**
 * A list of supported link attachments.
 */

@objc(ZMLinkAttachmentType)
public enum LinkAttachmentType: Int {
    case youTubeVideo = 1
    case soundCloudTrack = 2
    case soundCloudPlaylist = 3
}

// MARK: - Media Attachments

/**
 * Represents a link attachment for a single media.
 */

@objc(ZMLinkAttachment)
public class LinkAttachment: NSObject, NSSecureCoding {

    public static var supportsSecureCoding = true

    /// The type of the attached media.
    @objc public let type: LinkAttachmentType

    /// The title of the media.
    @objc public let title: String

    /// The permalink to the media on the provider's website.
    @objc public let permalink: URL

    /// The list of the video thumbnails.
    @objc public let thumbnails: [URL]

    /// The range of the attachment in the text.
    @objc public let originalRange: NSRange

    // MARK: Initialization

    /**
     * Creates a new media thumbnail reference.
     * - parameter type: The type of the attached media.
     * - parameter title: The title of the video.
     * - parameter permalink: The permalink to the media on the provider's website.
     * - parameter thumbnails: The list of the video thumbnails.
     * - parameter originalRange: The range of the attachment in the text.
     */

    @objc public init(type: LinkAttachmentType, title: String, permalink: URL, thumbnails: [URL], originalRange: NSRange) {
        self.type = type
        self.title = title
        self.permalink = permalink
        self.thumbnails = thumbnails
        self.originalRange = originalRange
    }

    // MARK: NSCoding

    public required init?(coder aDecoder: NSCoder) {
        guard
            let type = LinkAttachmentType(rawValue: aDecoder.decodeInteger(forKey: #keyPath(type))),
            let title = aDecoder.decodeObject(of: NSString.self, forKey: #keyPath(title)) as String?,
            let permalink = aDecoder.decodeObject(of: NSURL.self, forKey: #keyPath(permalink)) as URL?,
            let thumbnails = aDecoder.decodeObject(of: [NSArray.self, NSURL.self], forKey: #keyPath(thumbnails)) as? [URL],
            let originalRange = aDecoder.decodeObject(of: NSValue.self, forKey: #keyPath(originalRange))?.rangeValue
        else {
            return nil
        }

        self.type = type
        self.title = title
        self.permalink = permalink
        self.thumbnails = thumbnails
        self.originalRange = originalRange
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: #keyPath(type))
        aCoder.encode(title as NSString, forKey: #keyPath(title))
        aCoder.encode(permalink as NSURL, forKey: #keyPath(permalink))
        aCoder.encode(thumbnails as NSArray, forKey: #keyPath(thumbnails))
        aCoder.encode(NSValue(range: originalRange), forKey: #keyPath(originalRange))
    }

}

// MARK: - OpenGraph Data

extension LinkAttachment {

    /// Tries to create the link attachment from OpenGraph data.
    convenience init?(openGraphData: OpenGraphData, detectedType: LinkAttachmentType, originalRange: NSRange) {
        switch detectedType {
        case .soundCloudPlaylist:
            guard openGraphData.type.hasPrefix("music.playlist") || openGraphData.type.hasPrefix("soundcloud:set") else { return nil }
        case .soundCloudTrack:
            guard openGraphData.type.hasPrefix("music.song") || openGraphData.type.hasPrefix("soundcloud:sound") else { return nil }
        case .youTubeVideo:
            guard openGraphData.type.hasPrefix("video") else { return nil }
        }

        let thumbnails = openGraphData.imageUrls.compactMap(URL.init)
        guard let permalink = URL.init(string: openGraphData.resolvedURL) else { return nil }

        self.init(type: detectedType, title: openGraphData.title, permalink: permalink, thumbnails: thumbnails, originalRange: originalRange)
    }

}
