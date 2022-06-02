//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension BackendEnvironment {
    public enum FetchError: String, Error {
        case requestFailed
        case invalidResponse
    }
    
    public static func fetchEnvironment(url: URL, onCompletion: @escaping (Result<BackendEnvironment>) -> ()) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                Logging.backendEnvironment.error("Error fetching configuration from \(url): \(error)")
                onCompletion(.failure(error))
            } else if let data = data {
                if let environment = BackendEnvironment(environmentType: .custom(url: url), data: data) {
                    Logging.backendEnvironment.info("Fetched custom configuration from \(url)")
                    onCompletion(.success(environment))
                } else {
                    Logging.backendEnvironment.info("Error parsing response from \(url)")
                    onCompletion(.failure(FetchError.invalidResponse))
                }
            } else {
                Logging.backendEnvironment.info("Error fetching configuration from \(url)")
                onCompletion(.failure(FetchError.requestFailed))
            }
        }.resume()
    }
}
