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
import Ziphy

extension ZiphyClient {

    private static let ziphyCache: URLCache = {
        return URLCache(memoryCapacity: 100, diskCapacity: 200, diskPath: nil)
    }()

    static var `default`: ZiphyClient {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = ziphyCache

        let downloadSession = URLSession(configuration: sessionConfiguration)
        return ZiphyClient(host: "api.giphy.com", requester: ZMUserSession.shared()!, downloadSession: downloadSession)
    }

}
