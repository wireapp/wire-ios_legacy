//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSyncEngine

// This protocol describes the input for a `CallActionsView`.
protocol CallActionsViewInputType: CallTypeProvider, ColorVariantProvider {
    var canToggleMediaType: Bool { get }
    var isMuted: Bool { get }
    var mediaState: MediaState { get }
    var permissions: CallPermissionsConfiguration { get }
    var cameraType: CaptureDevice { get }
    var networkQuality: NetworkQuality { get }
    var callState: CallStateExtending { get }
    var videoGridPresentationMode: VideoGridPresentationMode { get }
    var allowPresentationModeUpdates: Bool { get }
}

extension CallActionsViewInputType {
    var appearance: CallActionAppearance {
        guard CallingConfiguration.config.isAudioCallColorSchemable else {
            return .dark(blurred: true)
        }

        switch (isVideoCall, variant) {
        case (true, _): return .dark(blurred: true)
        case (false, .light): return .light
        case (false, .dark): return .dark(blurred: false)
        }
    }
}
