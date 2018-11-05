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

class ConversationMessageCellTableViewAdapter<C: ConversationMessageCellDescription>: UITableViewCell {
    
    var cellView: C.View

    var cellDescription: C? {
        didSet {
            longPressGesture.isEnabled = cellDescription?.supportsActions == true
            doubleTapGesture.isEnabled = cellDescription?.supportsActions == true
        }
    }

    var isFullWidth: Bool = false {
        didSet {
            configureConstraints(fullWidth: isFullWidth)
        }
    }

    private var leading: NSLayoutConstraint!
    private var top: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var bottom: NSLayoutConstraint!

    private var longPressGesture: UILongPressGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellView = C.View(frame: .zero)
        self.cellView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.focusStyle = .custom
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.isOpaque = false
        
        contentView.addSubview(cellView)

        leading = cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        trailing = cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        top = cellView.topAnchor.constraint(equalTo: contentView.topAnchor)
        bottom = cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottom.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([leading, trailing, top, bottom])

        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        contentView.addGestureRecognizer(longPressGesture)

        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with object: C.View.Configuration, fullWidth: Bool) {
        cellView.configure(with: object)
        self.isFullWidth = fullWidth
    }

    func configureConstraints(fullWidth: Bool) {
        leading.constant = fullWidth ? 0 : UIView.conversationLayoutMargins.left
        trailing.constant = fullWidth ? 0 : -UIView.conversationLayoutMargins.right
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureConstraints(fullWidth: isFullWidth)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        UIView.animate(withDuration: 0.35, animations: {
            self.cellView.isSelected = selected
            self.layoutIfNeeded()
        })
    }

    // MARK: - Menu

    @objc private func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            self.showMenu()
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let actionController = cellDescription?.actionController else {
            return false
        }

        return actionController.canPerformAction(action) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return cellDescription?.actionController
    }

    private func showMenu() {
        guard cellDescription?.actionController != nil, cellDescription?.supportsActions == true else {
            return
        }

        let menu = UIMenuController.shared
        menu.menuItems = ConversationCellActionController.allMessageActions

        self.becomeFirstResponder()

        menu.setTargetRect(contentView.bounds, in: self)
        menu.setMenuVisible(true, animated: true)
    }

    // MARK: - Double Tap To Like

    @objc private func onDoubleTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .recognized {
            likeMessage()
        }
    }

    // MARK: - Standard Actions

    private func likeMessage() {
        guard cellDescription?.supportsActions == true else {
            return
        }

        cellDescription?.actionController?.likeMessage()
    }


}

extension UITableView {

    func register<C: ConversationMessageCellDescription>(cell: C.Type) {
        let reuseIdentifier = String(describing: C.View.self)
        register(ConversationMessageCellTableViewAdapter<C>.self, forCellReuseIdentifier: reuseIdentifier)
    }

    func dequeueConversationCell<C: ConversationMessageCellDescription>(for type: C.Type, description: C, for indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: C.View.self)

        let cell = dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as Any as! ConversationMessageCellTableViewAdapter<C>

        cell.cellDescription = description
        cell.configure(with: description.configuration, fullWidth: description.isFullWidth)

        return cell
    }
    
}
