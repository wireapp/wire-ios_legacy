//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public extension ConversationCell {
    func willDisplayInTableView() {
        if layoutProperties.showBurstTimestamp {
            burstTimestampTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.updateBurstTimestamp), userInfo: nil, repeats: true)
        }
        contentView.bringSubview(toFront: likeButton)

        if delegate != nil &&
            delegate.responds(to: #selector(ConversationCellDelegate.conversationCellShouldStartDestructionTimer)) &&
            delegate.conversationCellShouldStartDestructionTimer!(self) {
            updateCountdownView()
            if message.startSelfDestructionIfNeeded() {
                startCountdownAnimationIfNeeded(message)
            }
        }
        messageContentView.bringSubview(toFront: countdownContainerView)
    }

    @objc public func updateBurstTimestamp() {
        if layoutProperties.showDayBurstTimestamp {
            let serverTimestamp: Date? = message.serverTimestamp
            if serverTimestamp != nil {
                burstTimestampView.label.text = Message.dayFormatter(date: message.serverTimestamp!).string(from: message.serverTimestamp!).uppercased()
            }
            burstTimestampView.label.font = burstBoldFont
        }
        else {
            burstTimestampView.label.text = Message.formattedReceivedDate(for: message).uppercased()
            burstTimestampView.label.font = burstNormalFont
        }
        let hidden: Bool = !layoutProperties.showBurstTimestamp && !layoutProperties.showDayBurstTimestamp
        burstTimestampView.isSeparatorHidden = hidden
    }
}
