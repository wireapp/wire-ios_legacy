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
import WireUtilities

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

    /// Whether the cell supports actions.
    var supportsActions: Bool { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationCellDelegate? { get set }

    /// The action controller that handles the menu item.
    var actionController: ConversationCellActionController? { get set }

    /// The configuration object that will be used to populate the cell.
    var configuration: View.Configuration { get }

    /// Wheater the view should be displayed
    func visible(in context: ConversationMessageContext, selected: Bool) ->  Bool
    func register(in tableView: UITableView)
    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
}

// MARK: - Default implementation

extension ConversationMessageCellDescription {
    
    func visible(in context: ConversationMessageContext, selected: Bool) -> Bool {
        return true
    }
    
}

// MARK: - Table View Dequeuing

extension ConversationMessageCellDescription {

    func register(in tableView: UITableView) {
        tableView.register(cell: type(of: self))
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueConversationCell(with: self, for: indexPath)
    }
    
    func configureCell(_ cell: UITableViewCell) {
        guard let adapterCell = cell as? ConversationMessageCellTableViewAdapter<Self> else { return }
        
        adapterCell.cellView.configure(with: self.configuration)
    }
    
}

/**
 * A type erased box containing a conversation message cell description.
 */

@objc class AnyConversationMessageCellDescription: NSObject {
    private let cellGenerator: (UITableView, IndexPath) -> UITableViewCell
    private let registrationBlock: (UITableView) -> Void
    private let visibleBlock: (ConversationMessageContext, Bool) -> Bool
    private let configureBlock: (UITableViewCell) -> Void
    private let baseTypeGetter: () -> AnyClass

    private let _delegate: AnyMutableProperty<ConversationCellDelegate?>
    private let _message: AnyMutableProperty<ZMConversationMessage?>
    private let _actionController: AnyMutableProperty<ConversationCellActionController?>

    init<T: ConversationMessageCellDescription>(_ description: T) {
        registrationBlock = { tableView in
            description.register(in: tableView)
        }
        
        visibleBlock = { context, selected in
            return description.visible(in: context, selected: selected)
        }
        
        configureBlock = { cell in
            description.configureCell(cell)
        }

        cellGenerator = { tableView, indexPath in
            return description.makeCell(for: tableView, at: indexPath)
        }

        baseTypeGetter = {
            return T.self
        }

        _delegate = AnyMutableProperty(description, keyPath: \.delegate)
        _message = AnyMutableProperty(description, keyPath: \.message)
        _actionController = AnyMutableProperty(description, keyPath: \.actionController)
    }

    @objc var baseType: AnyClass {
        return baseTypeGetter()
    }

    @objc var delegate: ConversationCellDelegate? {
        get { return _delegate.getter() }
        set { _delegate.setter(newValue) }
    }

    @objc var message: ZMConversationMessage? {
        get { return _message.getter() }
        set { _message.setter(newValue) }
    }

    @objc var actionController: ConversationCellActionController? {
        get { return _actionController.getter() }
        set { _actionController.setter(newValue) }
    }
    
    func visible(in context: ConversationMessageContext, selected: Bool) -> Bool {
        return visibleBlock(context, selected)
    }
    
    func configure(cell: UITableViewCell) {
        configureBlock(cell)
    }

    @objc(registerInTableView:)
    func register(in tableView: UITableView) {
        registrationBlock(tableView)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cellGenerator(tableView, indexPath)
    }

}
