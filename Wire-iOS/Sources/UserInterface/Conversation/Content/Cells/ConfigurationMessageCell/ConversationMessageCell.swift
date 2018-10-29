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

import UIKit

/**
 * A generic view that displays conversation contents.
 */

protocol ConversationMessageCell {
    /// The object that contains the configuration of the view.
    associatedtype Configuration

    /// Whether the cell is selected.
    var isSelected: Bool { get set }

    /**
     * Configures the cell with the specified configuration object.
     * - parameter object: The view model for the cell.
     */

    func configure(with object: Configuration)
}

/**
 * An object that prepares the contents of a conversation cell before
 * it is displayed.
 *
 * The role of this object is to provide a `configuration` view model for
 * the view type it declares as the contents of the cell.
 */

protocol ConversationMessageCellDescription: class {
    /// The view that will be displayed for the cell.
    associatedtype View: ConversationMessageCell & UIView

    /// Whether the view occupies the entire width of the cell.
    var isFullWidth: Bool { get }

    /// The delegate for the cell.
    var delegate: ConversationCellDelegate? { get set }

    /// The configuration object that will be used to populate the cell.
    var configuration: View.Configuration { get }

    func register(in tableView: UITableView)
    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
}

extension ConversationMessageCellDescription {

    func register(in tableView: UITableView) {
        tableView.register(cell: type(of: self))
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueConversationCell(for: type(of: self), configuration: configuration, for: indexPath, fullWidth: isFullWidth)
    }

}

/**
 * A type erased box containing a conversation message cell description.
 */

@objc class AnyConversationMessageCellDescription: NSObject {
    private let cellGenerator: (UITableView, IndexPath) -> UITableViewCell
    private let registrationBlock: (UITableView) -> Void
    private let baseTypeGetter: () -> AnyClass
    private let fullWidthGetter: () -> Bool
    private let delegateGetter: () -> ConversationCellDelegate?
    private let delegateSetter: (ConversationCellDelegate?) -> Void

    init<T: ConversationMessageCellDescription>(_ description: T) {
        registrationBlock = { tableView in
            description.register(in: tableView)
        }

        cellGenerator = { tableView, indexPath in
            return description.makeCell(for: tableView, at: indexPath)
        }

        baseTypeGetter = {
            return T.self
        }

        fullWidthGetter = {
            return description.isFullWidth
        }

        delegateGetter = {
            return description.delegate
        }

        delegateSetter = { newValue in
            description.delegate = newValue
        }
    }

    @objc var baseType: AnyClass {
        return baseTypeGetter()
    }

    var isFullWidth: Bool {
        return fullWidthGetter()
    }

    @objc var delegate: ConversationCellDelegate? {
        get { return delegateGetter() }
        set { delegateSetter(newValue) }
    }

    @objc(registerInTableView:)
    func register(in tableView: UITableView) {
        registrationBlock(tableView)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cellGenerator(tableView, indexPath)
    }

}
