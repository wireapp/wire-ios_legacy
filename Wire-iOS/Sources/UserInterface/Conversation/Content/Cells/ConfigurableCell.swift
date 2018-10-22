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

protocol CellDescription {
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    
}

protocol ConfigurableCell: class {
    
    associatedtype Content
    associatedtype Configuration: Equatable
    
    static var reuseIdentifiers: [String] { get }
    static var mapping: [String: Configuration] { get }
    static func reuseIdentifier(for configuration: Configuration) -> String
    
    init(from configuration: Configuration)
    
    func configure(with content: Content)
    
    var isSelected: Bool { get set }
}

extension ConfigurableCell {
    
    static func reuseIdentifier(for configuration: Configuration) -> String {
        let foo = mapping.first { (keyValuePair) -> Bool in
            return configuration == keyValuePair.value
        }
        
        guard let reuseIdentifier = foo?.key else { fatal("Unknown cell configuration: \(configuration)") }
        
        return reuseIdentifier
    }
    
    static var reuseIdentifiers: [String] {
        return Array(mapping.keys)
    }
    
    init(reuseIdentifier: String) {
        guard let configuration = Self.mapping[reuseIdentifier] else { fatal("Unknown reuse identifier: \(reuseIdentifier)") }
        
        self.init(from: configuration)
    }
    
}
