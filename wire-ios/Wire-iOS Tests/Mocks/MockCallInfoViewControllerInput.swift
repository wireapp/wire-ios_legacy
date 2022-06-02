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
@testable import Wire

struct MockCallInfoViewControllerInput: CallInfoViewControllerInput {
    var allowPresentationModeUpdates: Bool
    var videoGridPresentationMode: VideoGridPresentationMode
    var videoPlaceholderState: CallVideoPlaceholderState
    var permissions: CallPermissionsConfiguration
    var degradationState: CallDegradationState
    var accessoryType: CallInfoViewControllerAccessoryType
    var canToggleMediaType: Bool
    var isMuted: Bool
    var callState: CallStateExtending
    var mediaState: MediaState
    var state: CallStatusViewState
    var isConstantBitRate: Bool
    var title: String
    var isVideoCall: Bool
    var disableIdleTimer: Bool
    var cameraType: CaptureDevice
    var networkQuality: NetworkQuality
    var userEnabledCBR: Bool
    var variant: ColorSchemeVariant
    var isForcedCBR: Bool
    var classification: SecurityClassification
}

extension MockCallInfoViewControllerInput: CustomDebugStringConvertible {}
