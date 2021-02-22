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
import WireDataModel

extension ZMConversationMessage {
    func audioCanBeSaved() -> Bool {
        if let fileMessageData = self.fileMessageData,
            let _ = fileMessageData.fileURL,
            fileMessageData.isAudio {
            return true
        }
        else {
            return false
        }
    }

    var audioTrack: AudioTrack? {
        return fileMessageData?.isAudio == true ? self as? AudioTrack : .none
    }
}

extension ZMAssetClientMessage: AudioTrack {
    var title: String? {
        get {
            guard let fileMessageData = self.fileMessageData else { return "" }

            return fileMessageData.filename
        }
    }
    var author: String? {
        get {
            return self.sender?.name
        }
    }

    var duration: TimeInterval {
        get {
            guard let fileMessageData = self.fileMessageData else { return 0 }

            return TimeInterval(Float(fileMessageData.durationMilliseconds) / 1000.0)
        }
    }

    var streamURL: URL? {
        get {
            guard let fileMessageData = self.fileMessageData,
                let fileURL = fileMessageData.fileURL else { return .none }

            return fileURL as URL?
        }
    }
    var failedToLoad: Bool {
        get {
            return false
        }
        set {
            // no-op
        }
    }
}
