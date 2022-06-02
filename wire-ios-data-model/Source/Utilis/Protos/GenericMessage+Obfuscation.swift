//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

public extension String {

    static func randomChar() -> UnicodeScalar {
        let string = "abcdefghijklmnopqrstuvxyz"
        let chars = Array(string.unicodeScalars)
        let random = UInt.secureRandomNumber(upperBound: UInt(chars.count))
        // in this case we know random will fit inside int
        return chars[Int(random)]
    }

    func obfuscated() -> String {
        var obfuscatedVersion = UnicodeScalarView()
        for char in self.unicodeScalars {
            if NSCharacterSet.whitespacesAndNewlines.contains(char) {
                obfuscatedVersion.append(char)
            } else {
                obfuscatedVersion.append(String.randomChar())
            }
        }
        return String(obfuscatedVersion)
    }
}

public extension GenericMessage {

    func obfuscatedMessage() -> GenericMessage? {
        guard let messageID = (messageID as String?).flatMap(UUID.init) else { return nil }
        guard case .ephemeral? = self.content else { return nil }

        if let someText = textData {
            let content = someText.content
            let obfuscatedContent = content.obfuscated()
            var obfuscatedLinkPreviews: [LinkPreview] = []
            if linkPreviews.count > 0 {
                let offset = linkPreviews.first!.urlOffset
                let offsetIndex = obfuscatedContent.index(obfuscatedContent.startIndex, offsetBy: Int(offset), limitedBy: obfuscatedContent.endIndex) ?? obfuscatedContent.startIndex
                let originalURL = obfuscatedContent[offsetIndex...]
                obfuscatedLinkPreviews = linkPreviews.map { $0.obfuscated(originalURL: String(originalURL)) }
            }

            let obfuscatedText = Text.with {
                $0.content = obfuscatedContent
                $0.mentions = []
                $0.linkPreview = obfuscatedLinkPreviews
            }

            return GenericMessage(content: obfuscatedText, nonce: messageID)
        }

        if let someAsset = assetData {
            let obfuscatedAsset = someAsset.obfuscated()
            return GenericMessage(content: obfuscatedAsset, nonce: messageID)
        }
        if locationData != nil {
            let obfuscatedLocation = Location(latitude: 0.0, longitude: 0.0)
            return GenericMessage(content: obfuscatedLocation, nonce: messageID)
        }
        return nil
    }
}

extension ImageAsset {
    func obfuscated() -> ImageAsset {
        return WireProtos.ImageAsset.with({
            $0.tag = tag
            $0.width = width
            $0.height = height
            $0.originalWidth = originalWidth
            $0.originalHeight = originalHeight
            $0.mimeType = mimeType
            $0.size = 1
        })
    }
}

extension LinkPreview {

    func obfuscated(originalURL: String) -> LinkPreview {
        let obfTitle = hasTitle ? title.obfuscated() : ""
        let obfSummary = hasSummary ? summary.obfuscated() : ""
        let obfImage = hasImage ? image.obfuscated() : nil
        return  LinkPreview.with {
            $0.url = originalURL
            $0.permanentURL = permanentURL.obfuscated()
            $0.urlOffset = urlOffset
            $0.title = obfTitle
            $0.summary = obfSummary
            if let obfImage = obfImage {
                $0.image = obfImage
            }
            $0.tweet = tweet.obfuscated()
            $0.article = Article.with {
                $0.title = obfTitle
                $0.summary = obfSummary
                $0.permanentURL = permanentURL.obfuscated()
                if let obfImage = obfImage {
                    $0.image = obfImage
                }
            }
        }
    }
}

extension Tweet {
    func obfuscated() -> Tweet {
        let obfAuthorName = hasAuthor ? author.obfuscated() : ""
        let obfUserName = hasUsername ? username.obfuscated() : ""
        return Tweet.with({
            $0.author = obfAuthorName
            $0.username = obfUserName
        })
    }
}

extension WireProtos.Asset {
    func obfuscated() -> WireProtos.Asset {
        var assetOriginal: WireProtos.Asset.Original?
        var assetPreview: WireProtos.Asset.Preview?

        if hasOriginal {
            assetOriginal = WireProtos.Asset.Original()
            if original.hasRasterImage {
                let imageMetaData = WireProtos.Asset.ImageMetaData.with {
                    $0.tag = original.image.tag
                    $0.width = original.image.width
                    $0.height = original.image.height
                }
                assetOriginal?.image = imageMetaData
            }

            if original.hasName {
                let obfName = original.name.obfuscated()
                assetOriginal?.name = obfName
            }

            let metaData = original.metaData
            switch metaData {
            case .audio?:
                assetOriginal?.audio = WireProtos.Asset.AudioMetaData()
            case .video?:
                assetOriginal?.video = WireProtos.Asset.VideoMetaData()
            default:
                break
            }
            assetOriginal?.size = 10
            assetOriginal?.mimeType = original.mimeType
        }

        if hasPreview {
            assetPreview = WireProtos.Asset.Preview()
            let imageMetaData = WireProtos.Asset.ImageMetaData.with {
                $0.tag = preview.image.tag
                $0.width = preview.image.width
                $0.height = preview.image.height
            }
            assetPreview?.image = imageMetaData
            assetPreview?.size = 10
            assetPreview?.mimeType = preview.mimeType
        }
        return WireProtos.Asset(original: assetOriginal, preview: assetPreview)
    }
}
