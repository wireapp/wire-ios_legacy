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

protocol CellConfigurationConfigurable: Reusable {
    func configure(with configuration: CellConfiguration, variant: ColorSchemeVariant)
}

enum CellConfiguration {
    typealias Action = (UIView?) -> Void
    case toggle(title: String,
                subtitle: String,
                identifier: String,
                titleIdentifier: String,
                get: () -> Bool,
                set: (Bool) -> Void)
    case linkHeader
    case leadingButton(title: String, identifier: String, action: Action)
    case loading
    case text(String)
    case iconAction(title: String,
                    icon: StyleKitIcon,
                    color: UIColor?,
                    action: Action)
    case iconToggle(title: String,
        subtitle: String,
        identifier: String,
        titleIdentifier: String,
        icon: StyleKitIcon,
        color: UIColor?,
        get: () -> Bool,
        set: (Bool) -> Void)

    var cellType: CellConfigurationConfigurable.Type {
        switch self {
        case .toggle: return ToggleSubtitleCell.self
        case .iconToggle: return IconToggleSubtitleCell.self
        case .linkHeader: return LinkHeaderCell.self
        case .leadingButton: return ActionCell.self
        case .loading: return LoadingIndicatorCell.self
        case .text: return TextCell.self
        case .iconAction: return IconActionCell.self
        }
    }
    
    var action: Action? {
        switch self {
        case .toggle,
             .iconToggle,
             .linkHeader,
             .loading,
             .text: return nil
        case let .leadingButton(_, _, action: action): return action
        case let .iconAction(_, _, _, action: action): return action
        }
    }
    
    // MARK: - Convenience
    
    static var allCellTypes: [UITableViewCell.Type] {
        return [
            ToggleSubtitleCell.self,
            LinkHeaderCell.self,
            ActionCell.self,
            LoadingIndicatorCell.self,
            TextCell.self,
            IconActionCell.self
        ]
    }
    
    static func prepare(_ tableView: UITableView) {
        allCellTypes.forEach {
            tableView.register($0, forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }

}
