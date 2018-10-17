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


protocol CellDescription: Codable {
    
    static var variants: [Self] { get }
    
}

extension CellDescription {
    
    var reuseIdentifier: String {
        let encoder = JSONEncoder()
        
        guard let asd = try? encoder.encode(CodableBox(value: self)), let encoded = String(data: asd, encoding: .utf8) else {
            return ""
        }
        
        return encoded
    }
    
    init?(from reuseIdentifier: String?) {
        let decoder = JSONDecoder()
        
        guard let reuseIdentifier = reuseIdentifier,
              let data = reuseIdentifier.data(using: .utf8),
              let box = try? decoder.decode(CodableBox<Self>.self, from: data) else {
                return nil
        }
        
        self = box.value
    }
    
}

protocol ConfigurableCell {
    
    associatedtype Content
    associatedtype Description: CellDescription
    
    init(from description: Description)
    
    func configure(with content: Content)
    
    var isSelected: Bool { get set }
}

struct CodableBox<T: Codable>: Codable {
    var value: T
}

struct MessageCellConfiguration: OptionSet, Codable {
    
    var rawValue: Int
    
    static var allCases: [MessageCellConfiguration] = [.none, .showSender, .showBurstTimestamp, .all]
    
    static let none = MessageCellConfiguration(rawValue: 0)
    static let showSender = MessageCellConfiguration(rawValue: 1 << 0)
    static let showBurstTimestamp = MessageCellConfiguration(rawValue: 1 << 1)
    static let all: MessageCellConfiguration = [.showSender, .showBurstTimestamp]
    
}

struct MessageCellDescription: CellDescription {
    
    var configuration: MessageCellConfiguration
    
    static var variants: [MessageCellDescription] = MessageCellConfiguration.allCases.map(MessageCellDescription.init)
    
    init(_ configuration: MessageCellConfiguration) {
        self.configuration = configuration
    }
    
    init(layout: ConversationCellLayoutProperties) {
        
        var configuration = MessageCellConfiguration()
        
        if layout.showBurstTimestamp {
            configuration.insert(.showBurstTimestamp)
        }
        
        if layout.showSender {
            configuration.insert(.showSender)
        }
        
        self.configuration = configuration
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

struct TextCellDescription: CellDescription {
    
    enum Attachment: Int, Codable, CaseIterable {
        case none
        case linkPreview
        case youtube
        case soundcloud
    }
    
    static var variants: [TextCellDescription] {
        
        var textCellDescriptions: [TextCellDescription] = []
        
        MessageCellDescription.variants.forEach { messageCelldescription in
            Attachment.allCases.forEach { attachment in
                textCellDescriptions.append(TextCellDescription(messageCelldescription, attachment: attachment))
            }
        }
        
        return textCellDescriptions
    }
    
    var messageCelldescription: MessageCellDescription
    var attachment: Attachment = .none
    
    init(_ messageCelldescription: MessageCellDescription, attachment: Attachment) {
        self.messageCelldescription = messageCelldescription
        self.attachment = attachment
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

class TableViewCellDescriptionAdapter<C: ConfigurableCell> : UITableViewCell where C : UIView {
    
    var cellView: C
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        guard let description = C.Description(from: reuseIdentifier) else {
            preconditionFailure("Unknown cell reuseIdentifier: \(String(describing: reuseIdentifier))")
        }
        
        self.cellView = C(from: description)
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
    
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        super.setHighlighted(highlighted, animated: animated)
//        cellView.isSelected = highlighted
//    }
    
    
}

extension UITableView {
    
    func register<C: ConfigurableCell>(cell: C.Type) where C : UIView{
        
        cell.Description.variants.forEach { variant in
            register(TableViewCellDescriptionAdapter<C>.self, forCellReuseIdentifier: variant.reuseIdentifier)
        }
        
    }
    
}
