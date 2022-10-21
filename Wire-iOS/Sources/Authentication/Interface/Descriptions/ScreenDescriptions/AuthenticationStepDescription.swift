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
import UIKit

typealias AuthenticationSecondaryViewDescription = SecondaryViewDescription & AuthenticationActionable

typealias AuthenticationFooterViewDescription = FooterViewDescription & AuthenticationActionable

typealias ValueSubmitted = (Any) -> Void
typealias ValueValidated = (ValueValidation?) -> Void

enum ValueValidation {
    case info(String)
    case error(TextFieldValidator.ValidationError, showVisualFeedback: Bool)
}

protocol ViewDescriptor: AnyObject {
    func create() -> UIView
}

protocol ValueSubmission: AnyObject {
    var acceptsInput: Bool { get set }
    var valueSubmitted: ValueSubmitted? { get set }
    var valueValidated: ValueValidated? { get set }
}

/// A protocol for views that support performing the magic tap.
protocol MagicTappable: AnyObject {
    func performMagicTap() -> Bool
}

protocol AuthenticationStepDescription {
    var backButton: BackButtonDescription? { get }
    var mainView: ViewDescriptor & ValueSubmission { get }
    var headline: String { get }
    var subtext: String? { get }
    var secondaryView: AuthenticationSecondaryViewDescription? { get }
    var footerView: AuthenticationFooterViewDescription? { get }
    func shouldSkipFromNavigation() -> Bool
}

protocol DefaultValidatingStepDescription: AuthenticationStepDescription {
    var initialValidation: ValueValidation { get }
}

extension AuthenticationStepDescription {
    func shouldSkipFromNavigation() -> Bool {
        return false
    }
}
