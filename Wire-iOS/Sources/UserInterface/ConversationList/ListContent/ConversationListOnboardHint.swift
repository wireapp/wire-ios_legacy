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
import UIKit

final class ConversationListOnboardingHint: UIView {
    
    let messageLabel: UILabel = UILabel()
    let arrowView: UIImageView = UIImageView()
    weak var arrowPointToView: UIView? {
        didSet {
            guard let arrowPointToView = arrowPointToView else { return }
            
            NSLayoutConstraint.activate([
            arrowView.centerXAnchor.constraint(equalTo: arrowPointToView.centerXAnchor)])
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        arrowView.setIcon(.longDownArrow, size: .large, color: UIColor.white.withAlphaComponent(0.4))
        
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        messageLabel.textAlignment = .left
        messageLabel.font = FontSpec(.large, .light).font
        messageLabel.text = "conversation_list.empty.no_contacts.message".localized
        
        [arrowView, messageLabel].forEach(self.addSubview)
        
        createConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createConstraints() {
        [arrowView, messageLabel].prepareForLayout()
        
        let margin: CGFloat = 24

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            arrowView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: margin),
            arrowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin)])
    }
}
