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
