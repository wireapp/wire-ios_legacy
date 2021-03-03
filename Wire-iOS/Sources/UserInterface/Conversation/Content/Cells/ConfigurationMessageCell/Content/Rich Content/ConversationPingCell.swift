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
import WireDataModel

class ConversationPingCell: ConversationIconBasedCell, ConversationMessageCell {

    typealias AnimationBlock = (_ animationBlock: Any, _ reps: Int) -> Void
    var animationBlock: AnimationBlock?
    var isAnimationRunning = false
    var configuration: Configuration?

    struct Configuration {
        let pingColor: UIColor
        let pingText: NSAttributedString
        var message: ZMConversationMessage?
    }

    func configure(with object: Configuration, animated: Bool) {
        self.configuration = object
        attributedText = object.pingText
        imageView.setIcon(.ping, size: 20, color: object.pingColor)
        lineView.isHidden = true
    }

    @objc func startAnimation() {
        self.animationBlock = createAnimationBlock()
        animate()
    }

    func stopAnimation() {
        self.isAnimationRunning = false
        self.imageView.alpha = 1.0
    }

    func animate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

            if !self.canAnimationContinue(for: self.configuration?.message) {
                return
            }

            self.isAnimationRunning = true
            self.imageView.alpha = 1.0
            self.animationBlock!(self.animationBlock as Any, 2)
        }
    }

    func createAnimationBlock() -> AnimationBlock {

        let animationBlock: AnimationBlock = { [weak self] otherBlock, reps in
            guard let `self` = self else { return }
            self.imageView.alpha = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {

                if !self.canAnimationContinue(for: self.configuration?.message) {
                    return
                }

                self.isAnimationRunning = true

                UIView.animate(easing: .easeOutExpo, duration: 0.7, animations: {
                    self.imageView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
                }, completion: { _ in
                    self.imageView.transform = .identity
                })

                UIView.animate(easing: .easeOutQuart, duration: 0.7, animations: {
                    self.imageView.alpha = 0.0
                }, completion: { _ in
                    if reps > 0 {
                        (otherBlock as! AnimationBlock)(self.animationBlock as Any, reps - 1)
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                             if !self.canAnimationContinue(for: self.configuration?.message) {
                                return
                             }

                            UIView.animate(easing: .easeOutQuart, duration: 0.55, animations: {
                                self.imageView.alpha = 1.0
                            }, completion: { (_) in
                                self.stopAnimation()
                            })
                        })
                    }
                })
            })

        }

        return animationBlock
    }

    func canAnimationContinue(for message: ZMConversationMessage?) -> Bool {
        return message?.knockMessageData?.isEqual(configuration?.message?.knockMessageData) ?? false
    }

    func willDisplay() {

        if let conversation = self.configuration?.message?.conversation,
           let lastMessage = conversation.lastMessage,
           let message = self.configuration?.message, lastMessage.isEqual(message) {

            if message.isKnock {
                startAnimation()
            }
        }
    }
}

class ConversationPingCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationPingCell
    let configuration: ConversationPingCell.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool {
        get { return false }
        set { /* pings doesn't support the ephemeral timer */ }
    }

    var topMargin: Float = 0
    let isFullWidth: Bool = true
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, sender: UserType) {
        let senderText = sender.isSelfUser ? "content.ping.text.you".localized : (sender.name ?? "")
        let pingText = "content.ping.text".localized(pov: sender.pov, args: senderText)

        let text = NSAttributedString(string: pingText, attributes: [
            .font: UIFont.mediumFont,
            .foregroundColor: UIColor.from(scheme: .textForeground)
            ]).adding(font: .mediumSemiboldFont, to: senderText)

        let pingColor: UIColor = message.isObfuscated ? .accentDimmedFlat : sender.accentColor
        self.configuration = View.Configuration(pingColor: pingColor, pingText: text, message: message)
        actionController = nil
    }

}
