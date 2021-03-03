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

import UIKit

/**
 * Represents a request for the user to input text in an alert.
 */

struct UserInputRequest {

    /**
     * Represents the configuration of an alert text field.
     */

    struct InputConfiguration {
        /// The placeholder of the text field.
        let placeholder: String

        /// The prefilled text.
        let prefilledText: String?

        /// Whether the request is for a password.
        let isSecure: Bool

        /// The content type of the request.
        let textContentType: UITextContentType?

        /// The accessibility identifier of the text field.
        let accessibilityIdentifier: String

        /// The block to use to validate user input.
        let validator: (String) -> Bool
    }

    /// The title of the input alert.
    let title: String

    /// The message of the input alert.
    let message: String

    /// The title of the continue button.
    let continueActionTitle: String

    /// The title of the cancel button.
    let cancelActionTitle: String

    /// The configuration for user input, or nil if the password is not needed.
    let inputConfiguration: InputConfiguration?

    /// The block to execute when the user taps the continue button.
    let completionHandler: (String?) -> Void

    /// The block to execute when the user taps the cancel button.
    let cancellationHandler: () -> Void

}

// MARK: - UIAlertController + UserInputRequest

extension UIAlertController {

    /**
     * Creates an alert controller to ask the user for input.
     * - parameter inputRequest: The description of the data the user needs to input.
     */

    convenience init(inputRequest: UserInputRequest) {
        self.init(title: inputRequest.title, message: inputRequest.message, preferredStyle: .alert)

        // Configure the observers
        var token: Any?

        func tearDown() {
            token.apply(NotificationCenter.default.removeObserver)
        }

        // Configure the actions
        let continueAction = UIAlertAction(title: inputRequest.continueActionTitle, style: .default) { _ in
            tearDown()
            inputRequest.completionHandler(self.textFields?.first?.text)
        }

        let cancelAction = UIAlertAction(title: inputRequest.cancelActionTitle, style: .cancel) { _ in
            tearDown()
            inputRequest.cancellationHandler()
        }

        // Configure the text field
        if let inputConfiguration = inputRequest.inputConfiguration {
            addTextField { textField in
                textField.text = inputConfiguration.prefilledText
                textField.accessibilityIdentifier = inputConfiguration.accessibilityIdentifier
                textField.placeholder = inputConfiguration.placeholder
                textField.isSecureTextEntry = inputConfiguration.isSecure
                textField.textContentType = inputConfiguration.textContentType

                token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                    continueAction.isEnabled = textField.text.map(inputConfiguration.validator) ?? false
                }

                // Enable the continue button initially if the prefilled code is valid.
                continueAction.isEnabled = inputConfiguration.prefilledText.map(inputConfiguration.validator) ?? false
            }
        }

        addAction(cancelAction)
        addAction(continueAction)
        preferredAction = continueAction
    }

}
