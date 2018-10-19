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
    
    init(reuseIdentifier: String)
    
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
    
    init(from configuration: Configuration) {
        self.init(reuseIdentifier: Self.reuseIdentifier(for: configuration))
    }
    
}

struct MessageCellConfiguration: OptionSet {
    
    var rawValue: Int
    
    static var allCases: [MessageCellConfiguration] = [.none, .showSender, .showBurstTimestamp, .all]
    
    static let none = MessageCellConfiguration(rawValue: 0)
    static let showSender = MessageCellConfiguration(rawValue: 1 << 0)
    static let showBurstTimestamp = MessageCellConfiguration(rawValue: 1 << 1)
    static let all: MessageCellConfiguration = [.showSender, .showBurstTimestamp]
    
    init(context: MessageCellContext) {
        var configuration = MessageCellConfiguration()
        
        if !context.isSameSenderAsPrevious {
            configuration.insert(.showSender)
        }
        
        if context.isTimeIntervalSinceLastMessageSignificant {
            configuration.insert(.showBurstTimestamp)
        }
        
        self.rawValue = configuration.rawValue
    }
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
}


struct UnknownMessageCellDescription: CellDescription {
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: ConversationUnknownMessageCellId, for: indexPath)
    }
    
}

extension UIView {
    
    func createConstraints(_ views: [(UIView, UIEdgeInsets)]) {
        
        var constraints: [NSLayoutConstraint] = []
        
        if let (firstView, insets) = views.first {
            constraints += [firstView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)]
        }
        
        for (view, insets) in views {
            constraints += [
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
                view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
            ]
        }
        
        for ((view, viewInsets), (precedingView, precedingViewInsets)) in zip(views.dropFirst(), views.dropLast()) {
            constraints += [view.topAnchor.constraint(equalTo: precedingView.bottomAnchor, constant: max(viewInsets.top, precedingViewInsets.bottom))]
        }
        
        if let (lastView, insets) = views.last {
            constraints += [lastView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)]
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
}

class TableViewConfigurableCellAdapter<C: ConfigurableCell> : UITableViewCell where C : UIView {
    
    var cellView: C
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        guard let reuseIdentifier = reuseIdentifier else {
            preconditionFailure("Missing cell reuseIdentifier")
        }
        
        self.cellView = C(reuseIdentifier: reuseIdentifier)
        self.cellView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.focusStyle = .custom
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.isOpaque = false

        contentView.addSubview(cellView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: cellView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with content: C.Content) {
        cellView.configure(with: content)
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
    
    func register<C: ConfigurableCell>(cell: C.Type) where C : UIView {
        cell.reuseIdentifiers.forEach { reuseIdentifier in
            register(TableViewConfigurableCellAdapter<C>.self, forCellReuseIdentifier: reuseIdentifier)
        }
    }
    
    func dequeueConfigurableCell<C: ConfigurableCell>(configuration: C.Configuration, for indexPath: IndexPath) -> TableViewConfigurableCellAdapter<C> {
        let cell = dequeueReusableCell(withIdentifier: C.reuseIdentifier(for: configuration), for: indexPath)
        
        return (cell as Any) as! TableViewConfigurableCellAdapter<C>
    }
    
}

class SenderView: UIView {
    
    let avatarSpacer = UIView()
    let avatar = UserImageView()
    let authorLabel = UILabel()
    var stackView: UIStackView!
    var avatarSpacerWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setUp()
    }
    
    func setUp() {
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.font = .normalLightFont
        authorLabel.accessibilityIdentifier = "author.name"
        
        avatar.userSession = ZMUserSession.shared()
        avatar.initials.font = .avatarInitial
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false
        
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [avatarSpacer, authorLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        createConstraints()
    }
    
    func createConstraints() {
        let avatarSpacerWidthConstraint = avatarSpacer.widthAnchor.constraint(equalToConstant: UIView.conversationLayoutMargins.left)
        self.avatarSpacerWidthConstraint = avatarSpacerWidthConstraint
        
        NSLayoutConstraint.activate([
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UIView.conversationLayoutMargins.right),
            ])
    }
    
    func configure(with user: UserType) {
        avatar.user = user
        authorLabel.text = user.displayName
    }
    
}
