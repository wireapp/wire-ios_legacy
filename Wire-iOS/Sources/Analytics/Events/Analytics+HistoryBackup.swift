////
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

enum BackupEvent: Event {
    case importSuceeded
    case importFailed
    case exportSucceeded(zipURL: URL)
    case exportFailed
    
    var name: String {
        switch self {
        case .importSuceeded: return "" // TODO
        case .importFailed: return "" // TODO
        case .exportSucceeded: return "" // TODO
        case .exportFailed: return "" // TODO
        }
    }
    
    var attributes: [AnyHashable : Any]? {
        switch self {
        case .importSuceeded, .importFailed, .exportFailed: return nil
        case .exportSucceeded(zipURL: let url): return ["size": url.fileSize ?? 0]
        }
    }
}

fileprivate extension URL {
    var fileSize: Int? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        return attributes?[.size] as? Int
    }
}
