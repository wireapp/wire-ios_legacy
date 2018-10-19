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

struct ImageMessageCellConfiguration: Equatable {
    
    var configuration: MessageCellConfiguration
    
    static var variants: [ImageMessageCellConfiguration] = MessageCellConfiguration.allCases.map({
        return ImageMessageCellConfiguration($0)
    })
    
    init(_ configuration: MessageCellConfiguration) {
        self.configuration = configuration
    }
    
}

struct ImageMessageCellDescription: CellDescription {
    
    let message: ZMConversationMessage
    let configuration: ImageMessageCellConfiguration
    
    init (message: ZMConversationMessage, context: MessageCellContext) {
        self.message = message
        self.configuration = ImageMessageCellConfiguration(MessageCellConfiguration(context: context))
    }
    
    func cell(tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewConfigurableCellAdapter<NewImageMessageCell> = tableView.dequeueConfigurableCell(configuration: configuration, for: indexPath)
        cell.configure(with: self)
        return cell
    }
    
}


class ImageMessageContentView: UIView {
    
    var imageView = ImageResourceView()
    var imageAspectConstraint: NSLayoutConstraint?
    var imageWidthConstraint: NSLayoutConstraint
    var imageHeightConstraint: NSLayoutConstraint
    
    init() {
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 0)
        
        super.init(frame: .zero)
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageWidthConstraint.priority = .defaultLow
        imageHeightConstraint.priority = .defaultLow
        
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint,
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with content: ZMImageMessageData) {
        imageAspectConstraint.apply({ imageView.removeConstraint($0) })
        imageAspectConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: content.originalSize.height / content.originalSize.width)
        imageAspectConstraint?.isActive = true
        imageWidthConstraint.constant = content.originalSize.width
        imageHeightConstraint.constant = content.originalSize.height
        imageView.setImageResource(content.image)
    }
    
}

class NewImageMessageCell: MessageCell, ConfigurableCell {
    
    typealias Content = ImageMessageCellDescription
    typealias Configuration = ImageMessageCellConfiguration
    
    static var mapping : [String : ImageMessageCellConfiguration] = {
        var mapping: [String : ImageMessageCellConfiguration] = [:]
        
        for (index, variant) in ImageMessageCellConfiguration.variants.enumerated() {
            mapping["\(reuseIdentifier)_\(index)"] = variant
        }
        
        return mapping
    }()
    
    let imageMessageContentView: ImageMessageContentView
        
    required init(from configuration: ImageMessageCellConfiguration) {
        imageMessageContentView = ImageMessageContentView()
        
        super.init(from: configuration.configuration, content: imageMessageContentView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with content: ImageMessageCellDescription) {
        super.configure(with: content.message)
        
        guard let imageMessageData = content.message.imageMessageData else { return }
        
        imageMessageContentView.configure(with: imageMessageData)
    }
    
}
