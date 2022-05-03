//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

extension FontSpec {

    // MARK: - Small

    static var smallFont: Self {
        return self.init(.small, .none)
    }

    static var smallLightFont: Self {
        return self.init(.small, .light)
    }

    static var smallRegularFont: Self {
        return self.init(.small, .regular)
    }

    static var smallMediumFont: Self {
        return self.init(.small, .medium)
    }

    static var smallSemiboldFont: Self {
        return self.init(.small, .semibold)
    }

    // MARK: - Normal

    static var normalFont: Self {
        return self.init(.normal, .none)
    }

    static var normalLightFont: Self {
        return self.init(.normal, .light)
    }

    static var normalRegularFont: Self {
        return self.init(.normal, .regular)
    }

    static var normalMediumFont: Self {
        return self.init(.normal, .medium)
    }

    static var normalSemiboldFont: Self {
        return self.init(.normal, .semibold)
    }

    static var normalBoldFont: Self {
        return self.init(.normal, .bold)
    }

    // MARK: - Medium

    static var mediumFont: Self {
        return self.init(.medium, .none)
    }

    static var mediumSemiboldFont: Self {
        return self.init(.medium, .semibold)
    }

    static var mediumLightLargeTitleFont: Self {
        return self.init(.medium, .light, .largeTitle)
    }

    // MARK: - Large

    static var largeThinFont: Self {
        return self.init(.large, .thin)
    }

    static var largeLightFont: Self {
        return self.init(.large, .light)
    }

    static var largeRegularFont: Self {
        return self.init(.large, .regular)
    }

    static var largeMediumFont: Self {
        return self.init(.large, .medium)
    }

    static var largeSemiboldFont: Self {
        return self.init(.large, .semibold)
    }

}
