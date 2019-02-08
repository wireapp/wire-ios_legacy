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

typealias AuthenticationSecondaryViewDescription = SecondaryViewDescription & AuthenticationActionable

typealias ValueSubmitted = (Any) -> ()
typealias ValueValidated = (TextFieldValidator.ValidationError) -> ()

protocol ViewDescriptor: class {
    func create() -> UIView
}

protocol ValueSubmission: class {
    var acceptsInput: Bool { get set }
    var valueSubmitted: ValueSubmitted? { get set }
    var valueValidated: ValueValidated? { get set }
}

/// A protocol for views that support performing the magic tap.
protocol MagicTappable: class {
    func performMagicTap() -> Bool
}

protocol AuthenticationStepDescription {
    var backButton: BackButtonDescription? { get }
    var mainView: ViewDescriptor & ValueSubmission { get }
    var headline: String { get }
    var subtext: String? { get }
    var secondaryView: AuthenticationSecondaryViewDescription? { get }
    func shouldSkipFromNavigation() -> Bool
}

extension AuthenticationStepDescription {
    func shouldSkipFromNavigation() -> Bool {
        return false
    }
}
