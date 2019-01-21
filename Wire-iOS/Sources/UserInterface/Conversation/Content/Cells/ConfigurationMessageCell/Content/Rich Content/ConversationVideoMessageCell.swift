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

class ConversationVideoMessageCell: RoundedView, ConversationMessageCell {
    
    struct Configuration {
        let message: ZMConversationMessage
        let isObfuscated: Bool
    }
    
    private let transferView = VideoMessageView(frame: .zero)
    private let obfuscationView = ObfuscationView(icon: .videoMessage)
    
    weak var delegate: ConversationMessageCellDelegate? = nil
    weak var message: ZMConversationMessage? = nil
    
    var isSelected: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
        configureConstraints()
    }
    
    private func configureSubviews() {
        shape = .rounded(radius: 4)
        backgroundColor = .from(scheme: .placeholderBackground)
        clipsToBounds = true
        
        transferView.delegate = self
        obfuscationView.isHidden = true
        
        addSubview(self.transferView)
        addSubview(self.obfuscationView)
    }
    
    private func configureConstraints() {
        transferView.translatesAutoresizingMaskIntoConstraints = false
        obfuscationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 160.0),
            
            // transferView
            transferView.leadingAnchor.constraint(equalTo: leadingAnchor),
            transferView.topAnchor.constraint(equalTo: topAnchor),
            transferView.trailingAnchor.constraint(equalTo: trailingAnchor),
            transferView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // obfuscationView
            obfuscationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            obfuscationView.topAnchor.constraint(equalTo: topAnchor),
            obfuscationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            obfuscationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
    }
    
    func configure(with object: Configuration, animated: Bool) {
        transferView.configure(for: object.message, isInitial: false)
        self.obfuscationView.isHidden = !object.isObfuscated
        
    }
    
    override public var tintColor: UIColor! {
        didSet {
            self.transferView.tintColor = self.tintColor
        }
    }
    
    var selectionView: UIView! {
        return transferView
    }
    
    var selectionRect: CGRect {
        return transferView.bounds
    }
    
}

extension ConversationVideoMessageCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let message = message else { return }
        
        delegate?.perform(action: action, for: message)
    }
}

class ConversationVideoMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationVideoMessageCell
    let configuration: View.Configuration
    
    var topMargin: Float = 8
    var showEphemeralTimer: Bool = false
    
    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true
    
    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil
    
    init(message: ZMConversationMessage) {
        self.configuration = View.Configuration(message: message, isObfuscated: message.isObfuscated)
    }
    
}
