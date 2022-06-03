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

public struct OpenGraphData {
    let title: String
    let type: String
    let url: String
    let resolvedURL: String
    let imageUrls: [String]

    let siteName: OpenGraphSiteName
    let siteNameString: String?
    let content: String?
    let userGeneratedImage: Bool

    var foursquareMetaData: FoursquareMetaData?

    init(title: String, type: String?, url: String, resolvedURL: String, imageUrls: [String], siteName: String? = nil, description: String? = nil, userGeneratedImage: Bool = false) {
        self.title = title
        self.type = type ?? OpenGraphTypeType.website.rawValue
        self.url = url
        self.resolvedURL = resolvedURL
        self.imageUrls = imageUrls
        self.siteNameString = siteName
        self.siteName = siteName.map { OpenGraphSiteName(string: $0) ?? .other } ?? .other
        self.content = description
        self.userGeneratedImage = userGeneratedImage
    }
}

extension OpenGraphData: CustomStringConvertible {
    public var description: String {
        var description = "<\(Swift.type(of: self))> \(String(describing: siteNameString)): \(url):\n\t\(title)"
        if let content = content { description += "\n\(content)" }
        return description
    }
}

public struct FoursquareMetaData {
    let latitude: Float
    let longitude: Float

    init(latitude: Float, longitude: Float) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init?(propertyMapping mapping: OpenGraphData.PropertyMapping) {
        guard let latitude = mapping[.latitudeFSQ].flatMap(Float.init), let longitude = mapping[.longitudeFSQ].flatMap(Float.init) else { return nil }
        self.init(latitude: latitude, longitude: longitude)
    }
}

extension OpenGraphData {

    typealias PropertyMapping = [OpenGraphPropertyType: String]

    init?(propertyMapping mapping: PropertyMapping, resolvedURL: URL, images: [String]) {
        guard let title = mapping[.title],
            let url = mapping[.url] else { return nil }

        self.init(
            title: title,
            type: mapping[.type],
            url: url,
            resolvedURL: resolvedURL.absoluteString,
            imageUrls: images,
            siteName: mapping[.siteName],
            description: mapping[.description],
            userGeneratedImage: mapping[.userGeneratedImage] == "true"
        )

        foursquareMetaData = FoursquareMetaData(propertyMapping: mapping)
    }

}

extension OpenGraphData: Equatable {}

public func == (lhs: OpenGraphData, rhs: OpenGraphData) -> Bool {
    return lhs.title == rhs.title && lhs.type == rhs.type &&
        lhs.url == rhs.url && lhs.imageUrls == rhs.imageUrls &&
        lhs.siteName == rhs.siteName && lhs.content == rhs.content &&
        lhs.siteNameString == rhs.siteNameString && lhs.userGeneratedImage == rhs.userGeneratedImage &&
        lhs.foursquareMetaData == rhs.foursquareMetaData
}

extension FoursquareMetaData: Equatable {}

public func == (lhs: FoursquareMetaData, rhs: FoursquareMetaData) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension ArticleMetadata {
    public convenience init(openGraphData: OpenGraphData, originalURLString: String, offset: Int) {
        self.init(originalURLString: originalURLString, permanentURLString: openGraphData.url, resolvedURLString: openGraphData.resolvedURL, offset: offset)
        title = openGraphData.title
        summary = openGraphData.content
        guard let imageURL = openGraphData.imageUrls.compactMap(URL.init).first else { return }
        imageURLs.append(imageURL)
    }
}

extension FoursquareLocationMetadata {
    public convenience init?(openGraphData: OpenGraphData, originalURLString: String, offset: Int) {
        guard openGraphData.type  == OpenGraphTypeType.foursquare.rawValue && openGraphData.siteName == .foursquare else { return nil }

        self.init(originalURLString: originalURLString, permanentURLString: openGraphData.url, resolvedURLString: openGraphData.resolvedURL, offset: offset)
        title = openGraphData.title
        subtitle = openGraphData.content
        longitude = openGraphData.foursquareMetaData?.longitude
        latitude = openGraphData.foursquareMetaData?.latitude
        guard let imageURL = openGraphData.imageUrls.compactMap(URL.init).first else { return }
        imageURLs.append(imageURL)
    }
}

extension InstagramPictureMetadata {
    public convenience init?(openGraphData: OpenGraphData, originalURLString: String, offset: Int) {
        guard openGraphData.type == OpenGraphTypeType.instagram.rawValue && openGraphData.siteName == .instagram else { return nil }
        self.init(originalURLString: originalURLString, permanentURLString: openGraphData.url, resolvedURLString: openGraphData.resolvedURL, offset: offset)
        title = openGraphData.title
        subtitle = openGraphData.content
        guard let imageURL = openGraphData.imageUrls.compactMap(URL.init).first else { return }
        imageURLs.append(imageURL)
    }
}

extension TwitterStatusMetadata {

    public convenience init?(openGraphData: OpenGraphData, originalURLString: String, offset: Int) {
        guard openGraphData.type == OpenGraphTypeType.article.rawValue && openGraphData.siteName == .twitter else { return nil }
        self.init(originalURLString: originalURLString, permanentURLString: openGraphData.url, resolvedURLString: openGraphData.resolvedURL, offset: offset)

        message = tweetContentFromOpenGraphData(openGraphData)
        author = tweetAuthorFromOpenGraphData(openGraphData)
        imageURLs = openGraphData.userGeneratedImage ? openGraphData.imageUrls.compactMap(URL.init) : []
    }

    private func tweetContentFromOpenGraphData(_ data: OpenGraphData) -> String? {
        var tweet = data.content
        tweet = tweet?.replacingOccurrences(of: "“", with: "", options: .anchored, range: nil)
        tweet = tweet?.replacingOccurrences(of: "”", with: "", options: [.anchored, .backwards], range: nil)
        return tweet
    }

    private func tweetAuthorFromOpenGraphData(_ data: OpenGraphData) -> String {
        let authorSuffix = " on Twitter"
        return data.title.replacingOccurrences(of: authorSuffix, with: "", options: [.anchored, .backwards], range: nil)
    }
}

extension OpenGraphData {

    func linkPreview(_ originalURLString: String, offset: Int) -> LinkMetadata {
        return TwitterStatusMetadata(openGraphData: self, originalURLString: originalURLString, offset: offset) ??
            ArticleMetadata(openGraphData: self, originalURLString: originalURLString, offset: offset)
    }

}
