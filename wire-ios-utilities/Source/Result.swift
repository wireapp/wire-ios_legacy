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

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public enum VoidResult {
    case success
    case failure(Error)
}

public extension Result {
    func map<U>(_ transform: (T) throws -> U) -> Result<U> {
        switch self {
        case .success(let value):
            do {
                return .success(try transform(value))
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}

public extension Result {
    var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }
    
    var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

public extension VoidResult {
    init<T>(result: Result<T>) {
        switch result {
        case .success: self = .success
        case .failure(let error): self = .failure(error)
        }
    }
    
    init(error: Error?) {
        if let error = error {
            self = .failure(error)
        } else {
            self = .success
        }
    }
    
    var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}
