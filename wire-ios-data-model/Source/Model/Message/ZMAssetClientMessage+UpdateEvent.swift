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

extension ZMAssetClientMessage {
    override open func update(with updateEvent: ZMUpdateEvent, initialUpdate: Bool) {
        guard let message = GenericMessage(from: updateEvent) else { return }

        do {
            try setUnderlyingMessage(message)
        } catch {
            assertionFailure("Failed to set generic message: \(error.localizedDescription)")
            return
        }

        version = 3 // We assume received assets are V3 since backend no longer supports sending V2 assets.

        guard
            let assetData = message.assetData,
            let status = assetData.status
        else {
            return
        }

        switch status {
        case .uploaded(let data) where data.hasAssetID:
            updateTransferState(.uploaded, synchronize: false)
        case .notUploaded where transferState != .uploaded:
            switch assetData.notUploaded {
            case .cancelled:
                managedObjectContext?.delete(self)
            case .failed:
                updateTransferState(.uploadingFailed, synchronize: false)
            }
        default: break
        }
    }
}
