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
    static func showNewsletterSubscriptionDialog() {
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

        AppDelegate.shared().notificationsWindow?.rootViewController?.present(alertController, animated: true)
    }
}
