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

class ConfigurableCellTableViewAdapter<C: UIView & ConversationMessageCell>: UITableViewCell {
    
    var cellView: C

    var isFullWidth: Bool = false {
        didSet {
            configureConstraints(fullWidth: isFullWidth)
        }
    }

    private var leading: NSLayoutConstraint!
    private var top: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var bottom: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        guard let reuseIdentifier = reuseIdentifier else {
            preconditionFailure("Missing cell reuseIdentifier")
        }
        
        self.cellView = C(frame: .zero)
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
        bottom = cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with object: C.Configuration, fullWidth: Bool) {
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
    
}

extension UITableView {

    func register<C: ConversationMessageCellDescription>(cell: C.Type) {
        let reuseIdentifier = String(describing: C.View.self)
        register(ConfigurableCellTableViewAdapter<C.View>.self, forCellReuseIdentifier: reuseIdentifier)
    }

    func dequeueConversationCell<C: ConversationMessageCellDescription>(for type: C.Type, configuration: C.View.Configuration, for indexPath: IndexPath, fullWidth: Bool) -> UITableViewCell {
        let reuseIdentifier = String(describing: C.View.self)

        let cell = dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as Any as! ConfigurableCellTableViewAdapter<C.View>
        cell.configure(with: configuration, fullWidth: fullWidth)

        return cell
    }
    
}
