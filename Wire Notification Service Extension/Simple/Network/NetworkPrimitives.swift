//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

struct NetworkRequest {

    let path: String
    let httpMethod: HTTPMethod
    let contentType: ContentType
    let acceptType: AcceptType

}

enum HTTPMethod: String {

    case get = "GET"
    case post = "POST"

}

enum ContentType: String {

    case json = "application/json"

}

enum AcceptType: String {

    case json = "application/json"

}

enum NetworkResponse: CustomStringConvertible {

    case success(SuccessResponse)
    case failure(ErrorResponse)

    var description: String {
        switch self {
        case .success(let response):
            return response.description

        case .failure(let response):
            return response.description
        }
    }

}

struct SuccessResponse: CustomStringConvertible {

    let status: Int
    let data: Data

    var description: String {
        return "status: \(status), data: \(data)"
    }

}

struct ErrorResponse: Codable, Equatable, CustomStringConvertible {

    let code: Int
    let label: String
    let message: String

    var description: String {
        return "code: \(code), label: \(label), message: \(message)"
    }

}
