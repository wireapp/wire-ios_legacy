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

final class ConversationListOnboardingHint : UIView {
    
    let messageLabel : UILabel = UILabel()
    let arrowView : UIImageView = UIImageView()
    
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
        [arrowView, messageLabel].forEach() {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor), ///TODO: leading margin
            
            arrowView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            arrowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
            arrowView.centerXAnchor.constraint(equalTo: centerXAnchor) ///TODO: point to first icon
            ])
        
//        constrain(self, arrowView, messageLabel) { container, arrowView, messageLabel in
//            messageLabel.top == container.top
//            messageLabel.leading == container.leading
//            messageLabel.trailing == container.trailing
//
//            arrowView.top == messageLabel.bottom + 24
//            arrowView.bottom == container.bottom - 24
//            arrowView.centerX == container.centerX ///TODO point to first icon
//        }
    }
    
    
}
