
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

private let zmLog = ZMSLog(tag: "TextView+Clipboard")

import Foundation

extension TextView {

    override open func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        zmLog.debug("types available: \(pasteboard.types)")

        if pasteboard.hasImages {

            if let image = UIPasteboard.general.mediaAssets().first {
                textViewDelegate?.textView(self, hasImageToPaste: image)
            }
            ///TODO: more then 1?
        } else if pasteboard.hasStrings {
            super.paste(sender)
        } else if pasteboard.hasURLs {
            if (pasteboard.string?.count ?? 0) != 0 {
                super.paste(sender)
            } else if pasteboard.url != nil {
                super.paste(sender)
            }
        }
    }

}
