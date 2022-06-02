//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireProtos
import SwiftProtobuf

private let redactedValue = "<redacted>"

// MARK: - Text

fileprivate extension Text {
    func sanitize() -> Text {
        var text = self
        text.content = redactedValue
        text.linkPreview = text.linkPreview.map { $0.sanitize() }
        return text
    }
}

// MARK: - LinkPreview

fileprivate extension LinkPreview {
    func sanitize() -> LinkPreview {
        return LinkPreview(withOriginalURL: redactedValue,
                           permanentURL: redactedValue,
                           offset: urlOffset,
                           title: redactedValue,
                           summary: redactedValue,
                           imageAsset: image,
                           article: article.sanitize(),
                           tweet: nil)
    }
}

// MARK: - Article

fileprivate extension Article {
    func sanitize() -> Article {
        return Article.with {
            $0.title = redactedValue
            $0.permanentURL = redactedValue
            $0.summary = redactedValue
        }
    }
}

// MARK: - GenericMessage

 extension GenericMessage: CustomStringConvertible {
    public var description: String {
        var message = self
        guard let content = content else {
            return ""
        }
        switch content {
        case .text:
            message.text = text.sanitize()
        case .edited:
            message.edited.text = edited.text.sanitize()
        default:
            break
        }
        return message.debugDescription
    }
}
