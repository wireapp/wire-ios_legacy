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
import WireTransport

class TestTrustVerificator: NSObject, URLSessionDelegate {

    var session: URLSession!
    var trustProvider: BackendTrustProvider!
    private let callback: (Bool) -> Void

    init(trustProvider: BackendTrustProvider = MockCertificateTrust(), callback: @escaping (Bool) -> Void) {
        self.callback = callback
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.trustProvider = trustProvider
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else { return callback(false) }
        let trusted = trustProvider.verifyServerTrust(trust: protectionSpace.serverTrust!, host: protectionSpace.host)
        callback(trusted)
    }

    func verify(url: URL) {
        session.dataTask(with: url).resume()
    }

}
