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

@objc public extension ZMTransportRequest {
    
    var URL : URL {
        return Foundation.URL(string: self.path)!
    }
    
    var queryParameters : [String: Any] {
        return ((self.URL as NSURL).zm_queryComponents() as? [String: Any]) ?? [:]
    }
    
    var multipartBodyItemsFromRequestOrFile : [ZMMultipartBodyItem] {
        if let items = self.multipartBodyItems() as? [ZMMultipartBodyItem] {
            return items
        }
        
        guard let fileURL = self.fileUploadURL,
            let multipartData = try? Data(contentsOf: fileURL)
        else {
            return []
        }
        
        return ((multipartData as NSData).multipartDataItemsSeparated(withBoundary: "frontier") as? [ZMMultipartBodyItem]) ?? []
    }
    
    var binaryDataTypeAsMIME : String? {
        guard let dataType = self.binaryDataType else {
            return nil
        }
        return MockTransportSession.binaryDataType(asMIME: dataType)
    }
    
    @objc(RESTComponentAtIndex:) func RESTComponents(index: Int) -> String? {
        guard self.pathComponents.count > index, index > 0 else {
            return nil
        }
        return self.pathComponents[index]
    }
    
    fileprivate var pathComponents : [String] {
        return self.URL.path.components(separatedBy: "/").filter { !$0.isEmpty }
    }

}

@objc public extension ZMTransportRequest {
    /// Returns whether the path of the request matches the given string.
    /// Wildcards are allowed using the special symbol "*"
    /// E.g. `/users/ * /clients` will match `/users/ab12da/clients`
    func matches(path: String, method: ZMTransportRequestMethod) -> Bool {
        return self.method == method && self.matches(path: path)
    }
}

public extension ZMTransportRequest {
    
    /// Returns whether the path of the request matches the given string.
    /// Wildcards are allowed using the special symbol "*"
    /// E.g. `/users/ * /clients` will match `/users/ab12da/clients`
    func matches(path: String) -> Bool {
        let pathComponents = self.pathComponents
        let expectedComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard pathComponents.count == expectedComponents.count else {
            return false
        }
        
        return zip(expectedComponents, pathComponents).first(where: { (expected, actual) -> Bool in
            return expected != "*" && expected != actual
        }) == nil
    }

    static func ~=(path: String, request: ZMTransportRequest) -> Bool {
        return request.matches(path: path)
    }
}
