//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

enum TeamCreationState {
    case enterName
    case setEmail(teamName: String)
}

extension TeamCreationState {

    var backButtonDescription: BackButtonDescription? {
        switch self {
        case .enterName, .setEmail:
            return BackButtonDescription()
        }
    }

    var mainViewDescription: TextFieldDescription {
        switch self {
        case .enterName:
            return TextFieldDescription(placeholder: "Set team name")
        case .setEmail:
            return TextFieldDescription(placeholder: "Set email")
        }
    }

    var headline: String {
        switch self {
        case .enterName:
            return "Set team name"
        case .setEmail:
            return "Set email"
        }
    }

    var subtext: String? {
        switch self {
        case .enterName:
            return "You can always change it later"
        case .setEmail:
            return nil
        }
    }

    var secondaryViews: [ViewDescriptor] {
        return []
    }
}
