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

class MockProxiedURLRequester: NSObject, ProxiedURLRequester {

    func doRequest(withPath path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> ProxyRequest {
        return ProxyRequest(type: type, path: path, method: method, callback: completionHandler)
    }

    func respond(to request: ProxyRequest, data: Data?, response: HTTPURLResponse?, error: Error?) {
        request.callback?(data, response, error as NSError?)
    }

}
