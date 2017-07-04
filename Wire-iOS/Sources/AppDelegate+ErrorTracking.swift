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
                "metadata_keys" : metadata.keys.joined(separator: "; "),
                "user_info_keys" : userInfo.keys.joined(separator: "; "),
                "error_code" : error.code,
                "error_domain" : error.domain,
                "error_failure_reason" : error.localizedFailureReason?.truncatedForTracking() ?? "",
                "error_description" : error.description.truncatedForTracking(),
                "error_user_info" : error.userInfo.description.truncatedForTracking()
            ] as [String: Any]
            
            DispatchQueue.main.async {
                Analytics.shared()?.tagEvent(name, attributes: attributes)
            }
        })
    }
    
}


fileprivate extension String {

    func truncatedForTracking() -> String {
        return truncated(at: 100)
    }

    func truncated(at length: Int) -> String {
        guard characters.count > length else { return self }
        return substring(to: index(startIndex, offsetBy: length))
    }

}
