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

extension UIAlertController {

    /// flag for prevent showing newsletter subscription dialog again in team creation workflow.
    /// (team create work flow: newsletter subscription dialog appears after email verification.
    ///  email regisration work flow: newsletter subscription dialog appears after conversation list shows.)
    static var didNewsletterSubscriptionDialogShown = false

    static func showNewsletterSubscriptionDialogIfNeeded() {
        guard !UIAlertController.didNewsletterSubscriptionDialogShown else { return }
        
        let alertController = UIAlertController(title: "news_offers.consent.title".localized,
                                                message: "news_offers.consent.message".localized,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "general.accept".localized,
                                                style: .default,
                                                handler: { (_) in
                                                    // enable newsletter subscription
        }))

        alertController.addAction(UIAlertAction(title: "general.skip".localized,
                                                style: .cancel,
                                                handler: { (_) in
                                                    // disable newsletter subscription
        }))

        alertController.addAction(UIAlertAction(title: "news_offers.consent.button.privacy_policy.title".localized,
                                                style: .default,
                                                handler: { (_) in
                                                    // show privacy policy
        }))

        AppDelegate.shared().notificationsWindow?.rootViewController?.present(alertController, animated: true) {
            UIAlertController.didNewsletterSubscriptionDialogShown = true
        }

    }
}
