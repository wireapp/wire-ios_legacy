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

protocol ReplyComposingViewDelegate: NSObjectProtocol {
    func removeReply()
}

final class ReplyComposingView: UIView {
    let message: ZMConversationMessage
    private let closeButton = IconButton()
    private let leftSideView = UIView(frame: .zero)
    private let messagePreviewContainer = UIView(frame: .zero)
    weak var delegate: ReplyComposingViewDelegate? = nil
    private var observerToken: Any? = nil
    
    init(message: ZMConversationMessage) {
        self.message = message
        super.init(frame: .zero)
        
        setupMessageObserver()
        
        setupSubviews()
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageObserver() {
        observerToken = MessageChangeInfo.add(observer: self, for: message, userSession: ZMUserSession.shared()!)
    }
    
    private func setupSubviews() {
        leftSideView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        messagePreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        leftSideView.backgroundColor = .init(scheme: .background)
        messagePreviewContainer.backgroundColor = .red
        
        closeButton.accessibilityIdentifier = "cancelReply"
        closeButton.accessibilityLabel = "conversation.input_bar.close_reply".localized
        closeButton.setIcon(.X, with: .tiny, for: .normal)
        closeButton.setIconColor(.init(scheme: .iconNormal), for: .normal)
        closeButton.addCallback(for: .touchUpInside) { [weak self] _ in
            self?.delegate?.removeReply()
        }
        
        [leftSideView, messagePreviewContainer].forEach(self.addSubview)
        
        leftSideView.addSubview(closeButton)
    }
    
    private func setupConstraints() {
        let margins = UIView.directionAwareConversationLayoutMargins
        
        let constraints: [NSLayoutConstraint] = [
            leftSideView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftSideView.topAnchor.constraint(equalTo: topAnchor),
            leftSideView.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftSideView.widthAnchor.constraint(equalToConstant: margins.left),
            closeButton.centerXAnchor.constraint(equalTo: leftSideView.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: leftSideView.topAnchor, constant: 16),
            messagePreviewContainer.topAnchor.constraint(equalTo: topAnchor),
            messagePreviewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            messagePreviewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            messagePreviewContainer.leadingAnchor.constraint(equalTo: leftSideView.trailingAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension ReplyComposingView: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // TODO: update content view
    }
}
