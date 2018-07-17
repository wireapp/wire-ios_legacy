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

protocol SingleSignOnControllerDelegate: class {
    func controllerShouldPresentLoginCodeAlert(_ controller: SingleSignOnController)
    func controller(_ controller: SingleSignOnController, presentLoginAlert: UIAlertController)
}

@objc public final class SingleSignOnController: NSObject {

    weak var delegate: SingleSignOnControllerDelegate?
    private var token: Any?
    private let detector = SharedIdentitySessionRequestDetector.shared

    deinit {
        token.apply(NotificationCenter.default.removeObserver)
    }
    
    private func setupObservers() {
        token = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { [detectLoginCode] _ in
            detectLoginCode()
        }
    }
    
    @objc public func detectLoginCode() {
        detector.detectCopiedRequestCode { [processLoginCode] code in
            code.apply(processLoginCode)
        }
    }
    
    private func processLoginCode(_ uuid: UUID) {
        
    }
    
}
