//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@objc
public enum ProxiedRequestType: Int {
    case giphy, soundcloud, youTube
}

extension ZMUserSession {

    @objc(proxiedRequestWithPath:method:type:callback:) @discardableResult
    public func proxiedRequest(path: String, method: ZMTransportRequestMethod, type: ProxiedRequestType, callback: ProxyRequestCallback?) -> ProxyRequest {

        let request = ProxyRequest(type: type, path: path, method: method, callback: callback)

        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory?.proxiedRequestStatus.add(request: request)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }

        return request
    }

    @objc
    public func cancelProxiedRequest(_ request: ProxyRequest) {
        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory?.proxiedRequestStatus.cancel(request: request)
        }
    }

}
