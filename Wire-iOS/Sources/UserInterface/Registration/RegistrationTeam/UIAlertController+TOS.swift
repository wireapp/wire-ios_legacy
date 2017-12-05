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
import SafariServices

private final class SafariViewControllerBlockAPI: SFSafariViewController, SFSafariViewControllerDelegate {
    public var onDismiss: (()->())? = nil
    
    override init(url: URL, entersReaderIfAvailable: Bool) {
        super.init(url: url, entersReaderIfAvailable: entersReaderIfAvailable)
        
        self.delegate = self
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.onDismiss?()
    }
}

extension UIAlertController {
    static func requestTOSApproval(over controller: UIViewController, completion: @escaping (_ approved: Bool)->()) {
        let alert = UIAlertController(title: "registration.terms_of_use.terms.title".localized,
                                      message: "registration.terms_of_use.terms.message".localized,
                                      preferredStyle: .alert)
        let viewAction = UIAlertAction(title: "registration.terms_of_use.terms.view".localized, style: .default) { [weak controller] action in
            
            let webViewController = SafariViewControllerBlockAPI(url: NSURL.wr_termsOfServices().wr_URLByAppendingLocaleParameter() as URL, entersReaderIfAvailable: true)
            webViewController.onDismiss = { [weak controller] in
                if let controller = controller {
                    UIAlertController.requestTOSApproval(over: controller, completion: completion)
                }
            }
            controller?.present(webViewController, animated: true)
        }
        alert.addAction(viewAction)
        
        let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .default) { action in
            completion(false)
        }
        alert.addAction(cancelAction)
        
        let acceptAction = UIAlertAction(title: "registration.terms_of_use.accept".localized, style: .cancel) { action in
            completion(true)
        }
        alert.addAction(acceptAction)
        
        controller.present(alert, animated: true, completion: nil)
    }
}

