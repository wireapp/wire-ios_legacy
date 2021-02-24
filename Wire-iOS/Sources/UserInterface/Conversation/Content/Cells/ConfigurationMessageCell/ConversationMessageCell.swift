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
import WireDataModel


protocol ConversationMessageCellDelegate: MessageActionResponder {

    func conversationMessageShouldBecomeFirstResponderWhenShowingMenuForCell(_ cell: UIView) -> Bool
    func conversationMessageWantsToOpenUserDetails(_ cell: UIView, user: UserType, sourceView: UIView, frame: CGRect)
    func conversationMessageWantsToOpenMessageDetails(_ cell: UIView, messageDetailsViewController: MessageDetailsViewController)
    func conversationMessageWantsToOpenGuestOptionsFromView(_ cell: UIView, sourceView: UIView)
    func conversationMessageWantsToOpenParticipantsDetails(_ cell: UIView, selectedUsers: [UserType], sourceView: UIView)
    func conversationMessageShouldUpdate()
}

/**
 * A generic view that displays conversation contents.
 */

protocol ConversationMessageCell: class {
    /// The object that contains the configuration of the view.
    associatedtype Configuration

    /// Whether the cell is selected.
    var isSelected: Bool { get set }

    /// The view to highlight when the cell is selected.
    var selectionView: UIView? { get }

    /// The frame to highlight when the cell is selected.
    var selectionRect: CGRect { get }

    /// Top inset for ephemeral timer relative to the cell content
    var ephemeralTimerTopInset: CGFloat { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationMessageCellDelegate? { get set }

    /**
     * Configures the cell with the specified configuration object.
     * - parameter object: The view model for the cell.
     * - parameter animated: True if the view should animate the changes
     */

    func configure(with object: Configuration, animated: Bool)

    /// Called before the cell will be displayed on the screen.
    func willDisplay()

    /// Called after the cell as been moved off screen.
    func didEndDisplaying()
}

extension ConversationMessageCell {

    var selectionView: UIView? {
        return nil
    }

    var selectionRect: CGRect {
        return selectionView?.bounds ?? .zero
    }

    var ephemeralTimerTopInset: CGFloat {
        return 8
    }

    func willDisplay() {
        // to be overriden
    }

    func didEndDisplaying() {
        // to be overriden
    }

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

    /// The top margin is used to configure the spacing between cells. This property will
    /// get updated by the ConversationMessageSectionController if necessary so any
    /// default value is just a recommendation.
    var topMargin: Float { get set }

    /// Whether the view occupies the entire width of the cell.
    var isFullWidth: Bool { get }

    /// Whether the cell supports actions.
    var supportsActions: Bool { get }

    /// Whether the cell should display an ephemeral timer in the margin given it's an ephemeral message
    var showEphemeralTimer: Bool { get set }

    /// Whether the cell contains content that can be highlighted.
    var containsHighlightableContent: Bool { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationMessageCellDelegate? { get set }

    /// The action controller that handles the menu item.
    var actionController: ConversationMessageActionController? { get set }

    /// The configuration object that will be used to populate the cell.
    var configuration: View.Configuration { get }

    /// The accessibility identifier of the cell.
    var accessibilityIdentifier: String? { get }

    /// The accessibility label of the cell.
    var accessibilityLabel: String? { get }

    func register(in tableView: UITableView)
    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    func makeView() -> UIView
    func willDisplayCell()
    func didEndDisplayingCell()
    func isConfigurationEqual(with other: Any) -> Bool
}

// MARK: - Table View Dequeuing

extension ConversationMessageCellDescription {

    func willDisplayCell() {
        _ = message?.startSelfDestructionIfNeeded()
    }

    func didEndDisplayingCell() {

    }
    func register(in tableView: UITableView) {
        tableView.register(cell: type(of: self))
    }

    func makeView() -> UIView {
        let view = View()
        let container = UIView()

        view.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)

        let leading = view.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        let trailing = view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        let top = view.topAnchor.constraint(equalTo: container.topAnchor)
        let bottom = view.bottomAnchor.constraint(equalTo: container.bottomAnchor)

        top.constant = CGFloat(topMargin)
        leading.constant = isFullWidth ? 0 : view.conversationHorizontalMargins.left
        trailing.constant = isFullWidth ? 0 : -view.conversationHorizontalMargins.right

        NSLayoutConstraint.activate([leading, trailing, top, bottom])

        view.configure(with: configuration, animated: false)

        return container
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.cellView.delegate = delegate
        cell.cellView.message = message
        cell.accessibilityCustomActions = actionController?.makeAccessibilityActions()
        return cell
    }

    func configureCell(_ cell: UITableViewCell, animated: Bool = false) {
        guard let adapterCell = cell as? ConversationMessageCellTableViewAdapter<Self> else { return }

        adapterCell.cellView.configure(with: configuration, animated: animated)

        if cell.isVisible {
            _ = message?.startSelfDestructionIfNeeded()
        }
    }


    /// Default implementation of isConfigurationEqual. If the configure is Equatable, see below Conditionally Conforming for View.Configuration : Equatable
    ///
    /// - Parameter other: other object to compare
    /// - Returns: true if both self and other having same type
    func isConfigurationEqual(with other: Any) -> Bool {
        return type(of: self) == type(of: other)
    }

}

extension ConversationMessageCellDescription where View.Configuration: Equatable {

    /// Default implementation of isConfigurationEqual
    ///
    /// - Parameter other: other object to compare
    /// - Returns: true if both self and other having same type, and configures are equal
    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherConfig = (other as? Self)?.configuration else { return false }

        return configuration == otherConfig
    }
}

/**
 * A type erased box containing a conversation message cell description.
 */

class AnyConversationMessageCellDescription: NSObject {
    private let cellGenerator: (UITableView, IndexPath) -> UITableViewCell
    private let viewGenerator: () -> UIView
    private let registrationBlock: (UITableView) -> Void
    private let configureBlock: (UITableViewCell, Bool) -> Void
    private let baseTypeGetter: () -> AnyClass
    private let instanceGetter: () -> AnyObject
    private let isConfigurationEqualBlock: (AnyConversationMessageCellDescription) -> Bool

    private let _delegate: AnyMutableProperty<ConversationMessageCellDelegate?>
    private let _message: AnyMutableProperty<ZMConversationMessage?>
    private let _actionController: AnyMutableProperty<ConversationMessageActionController?>
    private let _topMargin: AnyMutableProperty<Float>
    private let _containsHighlightableContent: AnyConstantProperty<Bool>
    private let _showEphemeralTimer: AnyMutableProperty<Bool>
    private let _axIdentifier: AnyConstantProperty<String?>
    private let _axLabel: AnyConstantProperty<String?>
    private let _supportsActions: AnyConstantProperty<Bool>

    init<T: ConversationMessageCellDescription>(_ description: T) {
        registrationBlock = { tableView in
            description.register(in: tableView)
        }

        configureBlock = { cell, animated in
            description.configureCell(cell, animated: animated)
        }

        viewGenerator = {
            return description.makeView()
        }

        cellGenerator = { tableView, indexPath in
            return description.makeCell(for: tableView, at: indexPath)
        }

        baseTypeGetter = {
            return T.self
        }

        instanceGetter = {
            return description
        }

        isConfigurationEqualBlock = { otherDescription in
            description.isConfigurationEqual(with: otherDescription.instance)
        }

        _delegate = AnyMutableProperty(description, keyPath: \.delegate)
        _message = AnyMutableProperty(description, keyPath: \.message)
        _actionController = AnyMutableProperty(description, keyPath: \.actionController)
        _topMargin = AnyMutableProperty(description, keyPath: \.topMargin)
        _containsHighlightableContent = AnyConstantProperty(description, keyPath: \.containsHighlightableContent)
        _showEphemeralTimer = AnyMutableProperty(description, keyPath: \.showEphemeralTimer)
        _axIdentifier = AnyConstantProperty(description, keyPath: \.accessibilityIdentifier)
        _axLabel = AnyConstantProperty(description, keyPath: \.accessibilityLabel)
        _supportsActions = AnyConstantProperty(description, keyPath: \.supportsActions)
    }

    var instance: AnyObject {
        return instanceGetter()
    }

    var baseType: AnyClass {
        return baseTypeGetter()
    }

    var delegate: ConversationMessageCellDelegate? {
        get { return _delegate.getter() }
        set { _delegate.setter(newValue) }
    }

    var message: ZMConversationMessage? {
        get { return _message.getter() }
        set { _message.setter(newValue) }
    }

    var actionController: ConversationMessageActionController? {
        get { return _actionController.getter() }
        set { _actionController.setter(newValue) }
    }

    var topMargin: Float {
        get { return _topMargin.getter() }
        set { _topMargin.setter(newValue) }
    }

    var containsHighlightableContent: Bool {
        return _containsHighlightableContent.getter()
    }

    var showEphemeralTimer: Bool {
        get { return _showEphemeralTimer.getter() }
        set { _showEphemeralTimer.setter(newValue) }
    }

    /// The accessibility identifier of the cell.
    var cellAccessibilityIdentifier: String? {
        return _axIdentifier.getter()
    }

    /// The accessibility label of the cell.
    var cellAccessibilityLabel: String? {
        return _axLabel.getter()
    }

    /// Whether the cell supports actions.
    var supportsActions: Bool {
        return _supportsActions.getter()
    }

    func configure(cell: UITableViewCell, animated: Bool = false) {
        configureBlock(cell, animated)
    }

    func register(in tableView: UITableView) {
        registrationBlock(tableView)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cellGenerator(tableView, indexPath)
    }

    func makeView() -> UIView {
        return viewGenerator()
    }

    func isConfigurationEqual(with description: AnyConversationMessageCellDescription) -> Bool {
        return isConfigurationEqualBlock(description)
    }

}
