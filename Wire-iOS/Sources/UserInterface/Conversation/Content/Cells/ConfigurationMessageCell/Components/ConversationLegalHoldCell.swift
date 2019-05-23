//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

struct LegalHoldViewModel {
    let user: ZMUser
    let baseTemplate = "content.system.message_legal_hold"
    let legalHoldURL: URL = URL(string: "settings://legal-hold")! // TODO replace with correct url + implementation
    
    func image() -> UIImage? {
        return StyleKitIcon.legalholdactive.makeImage(size: .tiny, color: .vividRed)
    }
    
    func createSystemMessage(template: String) -> NSAttributedString {
        var updateText: NSAttributedString! = .none
        
        if user.isSelfUser {
            updateText = NSAttributedString(string: template.localized, attributes: ConversationSystemMessageCell.baseAttributes)
        } else if let otherUserName = user.name {
            updateText = NSAttributedString(string: template.localized(args: otherUserName), attributes: ConversationSystemMessageCell.baseAttributes)
                .adding(font: .mediumSemiboldFont, to: otherUserName)
        } else {
            assertionFailure("invalid user name for LegalHoldViewModel")
        }
        
        return updateText
    }
    
    func attributedTitle() -> NSAttributedString? {
        
        var template = baseTemplate
        
        template += user.isUnderLegalHold ? ".enabled" : ".disabled"
        template += user.isSelfUser ? ".you" : ".user"
        
        var updateText = createSystemMessage(template: template)
        
        if user.isUnderLegalHold {
            let learnMore = NSAttributedString(string: (baseTemplate + ".learn_more").localized.uppercased(),
                                               attributes: [.font: UIFont.mediumSemiboldFont,
                                                            .link: legalHoldURL as AnyObject,
                                                            .foregroundColor: UIColor.from(scheme: .textForeground)])
            
            updateText += " " + String.MessageToolbox.middleDot + " " + learnMore
        }
        
        return updateText
    }
}


final class ConversationLegalHoldCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell
    let configuration: View.Configuration
    
    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    
    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0
    
    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false
    
    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil
    
    init(sender: ZMUser,
        systemMessageType: ZMSystemMessageType) {
        let viewModel = LegalHoldViewModel(user: sender)
        
        configuration = View.Configuration(icon: viewModel.image(),
                                           attributedText: viewModel.attributedTitle(),
                                           showLine: false)
        actionController = nil
    }
}
