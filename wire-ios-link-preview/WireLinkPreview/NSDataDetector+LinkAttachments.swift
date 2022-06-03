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

import Foundation

extension NSDataDetector {

    /**
     * Returns attachment-eligible URLs found in text together with their range in within the text.
     * - parameter text: The text in which to search for URLs.
     * - parameter excludedRanges: Ranges within the text which should we excluded from the search.
     * - returns: The list of URL and their attachment type and range in the text.
     */

    public func detectLinkAttachments(in text: String, excluding excludedRanges: [NSRange] = []) -> [URL: (LinkAttachmentType, NSRange)] {
        let wholeTextRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        let validRangeIndexSet = NSMutableIndexSet(indexesIn: wholeTextRange)
        excludedRanges.forEach(validRangeIndexSet.remove)

        return matches(in: text, options: [], range: wholeTextRange).reduce(into: Dictionary()) {
            let range = $1.range
            guard let url = $1.url, validRangeIndexSet.contains(in: range) else { return }
            guard let type = matchYouTubeVideo(in: url) ?? matchSoundCloud(in: url) else { return }
            $0[url] = (type, range)
        }
    }

    private func matchYouTubeVideo(in url: URL) -> LinkAttachmentType? {
        // Match the domain
        guard let host = url.host else { return nil }

        switch host {
        case "youtube.com", "m.youtube.com", "www.youtube.com":
            guard url.pathComponents.element(atIndex: 1) ==  "watch" else { return nil }
            return .youTubeVideo

        case "youtu.be":
            guard url.pathComponents.count == 2 else { return nil }
            return .youTubeVideo

        default:
            return nil
        }
    }

    private func matchSoundCloud(in url: URL) -> LinkAttachmentType? {
        // Match the domain
        guard let host = url.host else { return nil }
        guard host == "soundcloud.com" || host == "m.soundcloud.com" || host == "www.soundcloud.com" else { return nil }

        let pathComponents = url.pathComponents

        if pathComponents.count == 3 {
            // Match soundcloud.com/<artist>/<track>
            return .soundCloudTrack
        } else if pathComponents.count == 4 && pathComponents.element(atIndex: 2) == "sets" {
            // Match soundcloud.com/<user>/sets/<playlist_name>
            return .soundCloudPlaylist
        }

        return nil
    }

}
