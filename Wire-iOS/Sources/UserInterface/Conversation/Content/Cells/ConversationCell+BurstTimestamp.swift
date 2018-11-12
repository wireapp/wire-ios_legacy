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

extension ConversationCell {
    @objc func setupFont() {
        burstNormalFont = UIFont.smallLightFont
        burstBoldFont = UIFont.smallSemiboldFont
    }
}

public extension ConversationCell {

    @objc func scheduledTimerForUpdateBurstTimestamp() {
        guard let _ = layoutProperties, layoutProperties.showBurstTimestamp else { return }

        burstTimestampTimer = .scheduledTimer(withTimeInterval: 60, repeats: true) {
            [weak self] _ in
            self?.updateBurstTimestamp()
        }
    }

    @objc func willDisplayInTableView() {
        scheduledTimerForUpdateBurstTimestamp()
        toolboxView.startCountdownTimer()

        if delegate != nil &&
            delegate.responds(to: #selector(ConversationCellDelegate.conversationCellShouldStartDestructionTimer)) &&
            delegate.conversationCellShouldStartDestructionTimer!(self) {
            updateCountdownView()

            if let message = message, message.startSelfDestructionIfNeeded() {
                startCountdownAnimationIfNeeded(message)
            }
        }

        messageContentView.bringSubviewToFront(countdownContainerView)
    }
    
    @objc func cellDidEndBeingVisible() {
        // no-op
    }

    @objc public func updateBurstTimestamp() {
        if layoutProperties.showDayBurstTimestamp {
            if let serverTimestamp = message.serverTimestamp {
                burstTimestampView.label.text = Message.dayFormatter(date: serverTimestamp).string(from: serverTimestamp).uppercased()
            } else {
                burstTimestampView.label.text = nil
            }

            burstTimestampView.label.font = burstBoldFont
        } else {
            burstTimestampView.label.text = Message.formattedReceivedDate(for: message).uppercased()
            burstTimestampView.label.font = burstNormalFont
        }
        let hidden: Bool = !layoutProperties.showBurstTimestamp && !layoutProperties.showDayBurstTimestamp
        burstTimestampView.isSeparatorHidden = hidden
    }
}
