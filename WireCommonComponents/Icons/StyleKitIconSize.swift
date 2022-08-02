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

import CoreGraphics

extension StyleKitIcon {

    /**
     * Represents the target size of an icon. You can either use standard values,
     * or use a raw CGFloat value, without needing to add another case.
     */

    public enum Size: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {

        /// 8pt
        case nano
        /// 16pt.
        case tiny
        /// 20pt.
        case small
        /// 24pt.
        case medium
        /// 48pt.
        case large
        /// A custom size.
        case custom(CGFloat)

        // MARK: - Literal Conversion

        public init(floatLiteral value: Double) {
            self = .custom(CGFloat(value))
        }

        public init(integerLiteral value: Int) {
            self = .custom(CGFloat(value))
        }

        // MARK: - CGFloat Conversion

        /// The value to use to generate the icon.
        public var rawValue: CGFloat {
            switch self {
            case .nano: return 8
            case .tiny: return 16
            case .small: return 20
            case .medium: return 24
            case .large: return 48
            case .custom(let value): return value
            }
        }

    }
}

public extension StyleKitIcon.Size {
    var cgSize: CGSize {
        return CGSize(width: rawValue, height: rawValue)
    }
}
