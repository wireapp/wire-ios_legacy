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
import WireCommonComponents
import UIKit
import WireSystem

final class ObfuscationView: UIImageView {
    init(icon: StyleKitIcon) {
        super.init(frame: .zero)
        backgroundColor = .accentDimmedFlat
        isOpaque = true
        contentMode = .center
        setIcon(icon, size: .tiny, color: UIColor.from(scheme: .background))

        switch icon {
        case .locationPin:
            accessibilityLabel = "Obfuscated location message"
        case .paperclip:
            accessibilityLabel = "Obfuscated file message"
        case .photo:
            accessibilityLabel = "Obfuscated image message"
        case .microphone:
            accessibilityLabel = "Obfuscated audio message"
        case .videoMessage:
            accessibilityLabel = "Obfuscated video message"
        case .link:
            accessibilityLabel = "Obfuscated link message"
        default:
            accessibilityLabel = "Obfuscated view"
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatal("initWithCoder: not implemented")
    }
}
