//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension AppDelegate {
    
    @objc public func trackErrors() {
        ZMUserSession.shared()?.registerForSaveFailure(handler: { (metadata, type, error, userInfo) in
            let name = "debug.database_context_save_failure"
            let attributes = [
                "context_type" : type.rawValue,
                "error_code" : error.code,
                "error_domain" : error.domain,
            ] as [String: Any]
            
            DispatchQueue.main.async {
                Analytics.shared().tagEvent(name, attributes: attributes)
            }
        })
    }
    
}
