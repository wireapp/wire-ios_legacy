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
import WireLinkPreview

extension ArticleMetadata {
    public convenience init(protocolBuffer: LinkPreview) {
        self.init(originalURLString: protocolBuffer.url,
                  permanentURLString: protocolBuffer.permanentURL,
                  resolvedURLString: protocolBuffer.permanentURL,
                  offset: Int(protocolBuffer.urlOffset))
        title = protocolBuffer.title.removingExtremeCombiningCharacters
        summary = protocolBuffer.summary.removingExtremeCombiningCharacters
    }
}

extension TwitterStatusMetadata {
    public convenience init(protocolBuffer: LinkPreview) {
        self.init(originalURLString: protocolBuffer.url,
                  permanentURLString: protocolBuffer.permanentURL,
                  resolvedURLString: protocolBuffer.permanentURL,
                  offset: Int(protocolBuffer.urlOffset))
        message = protocolBuffer.title.removingExtremeCombiningCharacters
        let newAuthor = protocolBuffer.hasTweet ? protocolBuffer.tweet.author : nil
        author = newAuthor?.removingExtremeCombiningCharacters
        let newUsername = protocolBuffer.hasTweet ? protocolBuffer.tweet.username : nil
        username = newUsername?.removingExtremeCombiningCharacters
    }
}
