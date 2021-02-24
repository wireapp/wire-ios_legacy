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
import UIKit
import WireCommonComponents

extension UIAlertController {

    /// flag for preventing newsletter subscription dialog shows again in team creation workflow.
    /// (team create work flow: newsletter subscription dialog appears after email verification.
    /// email regisration work flow: newsletter subscription dialog appears after conversation list is displayed.)
    static var newsletterSubscriptionDialogWasDisplayed = false

    static func showNewsletterSubscriptionDialog(over viewController: UIViewController, completionHandler: @escaping ResultHandler) {
        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts && !dataCollectionDisabled else { return }

        let alertController = UIAlertController(title: "news_offers.consent.title".localized,
                                                message: "news_offers.consent.message".localized,
                                                preferredStyle: .alert)

        let privacyPolicyActionHandler: ((UIAlertAction) -> Swift.Void) = { _ in
            let browserViewController = BrowserViewController(url: URL.wr_privacyPolicy.appendingLocaleParameter)

            browserViewController.completion = {
                UIAlertController.showNewsletterSubscriptionDialog(over: viewController, completionHandler: completionHandler)
            }

            viewController.present(browserViewController, animated: true)
        }

        alertController.addAction(UIAlertAction(title: "news_offers.consent.button.privacy_policy.title".localized,
                                                style: .default,
                                                handler: privacyPolicyActionHandler))

        alertController.addAction(UIAlertAction(title: "general.decline".localized,
                                                style: .default,
                                                handler: { (_) in
                                                    completionHandler(false)
        }))

        alertController.addAction(UIAlertAction(title: "general.accept".localized,
                                                style: .cancel,
                                                handler: { (_) in
                                                    completionHandler(true)
        }))

        UIAlertController.newsletterSubscriptionDialogWasDisplayed = true
        viewController.present(alertController, animated: true) {
            UIApplication.shared.keyWindow?.endEditing(true)
        }
    }

    private static  var dataCollectionDisabled: Bool {
        #if DATA_COLLECTION_DISABLED
        return true
        #else
        return false
        #endif
    }

    static func showNewsletterSubscriptionDialogIfNeeded(presentViewController: UIViewController,
                                                         completionHandler: @escaping ResultHandler) {
        guard !UIAlertController.newsletterSubscriptionDialogWasDisplayed else { return }

        showNewsletterSubscriptionDialog(over: presentViewController, completionHandler: completionHandler)
    }
}

extension AuthenticationCoordinatorAlert {

    static func makeMarketingConsentAlert() -> AuthenticationCoordinatorAlert {
        // Alert Actions
        let privacyPolicyAction = AuthenticationCoordinatorAlertAction(title: "news_offers.consent.button.privacy_policy.title".localized, coordinatorActions: [.showLoadingView, .openURL(URL.wr_privacyPolicy.appendingLocaleParameter)])
        let declineAction = AuthenticationCoordinatorAlertAction(title: "general.decline".localized, coordinatorActions: [.setMarketingConsent(false)])
        let acceptAction = AuthenticationCoordinatorAlertAction(title: "general.accept".localized, coordinatorActions: [.setMarketingConsent(true)])

        return AuthenticationCoordinatorAlert(title: "news_offers.consent.title".localized, message: "news_offers.consent.message".localized, actions: [privacyPolicyAction, declineAction, acceptAction])
    }

}
