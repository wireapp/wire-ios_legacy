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

enum OpenGraphAttribute {
    static let property = "property"
    static let content = "content"
}

enum OpenGraphXMLNode: String {
    case headStart = "<head "
    case headStartNoAttributes = "<head>"
    case headEnd = "</head>"
}

enum OpenGraphPropertyType: String {
    case title = "og:title"
    case type = "og:type"
    case image = "og:image"
    case url = "og:url"
    case description = "og:description"
    case siteName = "og:site_name"
    case userGeneratedImage = "og:image:user_generated"

    // MARK: Foursquare
    case latitudeFSQ = "playfoursquare:location:latitude"
    case longitudeFSQ = "playfoursquare:location:longitude"
}

enum OpenGraphSiteName: String {
    case other
    case twitter
    case vimeo
    case youtube
    case instagram
    case foursquare

    init?(string: String) {
        self.init(rawValue: string.lowercased())
    }
}

enum OpenGraphTypeType: String {
    case article = "article"
    case website = "website"
    case foursquare = "playfoursquare:venue"
    case instagram = "instapp:photo"
}
