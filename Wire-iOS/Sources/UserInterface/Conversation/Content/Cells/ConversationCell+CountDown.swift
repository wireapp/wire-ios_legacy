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

extension ConversationCell {
    @objc func updateCountdownView() {
        countdownContainerViewHidden = !showDestructionCountdown()

        guard !(countdownContainerViewHidden && nil != destructionLink) else {
            tearDownCountdown()
            return
        }

        guard showDestructionCountdown(), let destructionDate = message.destructionDate else { return }

        let duration = destructionDate.timeIntervalSinceNow

        if !countdownView.isAnimatingProgress && duration >= 1,
            let progress = message.countdownProgress {
            countdownView.startAnimating(duration: duration, currentProgress: CGFloat(progress))
            countdownView.isHidden = false
        }
        toolboxView.updateTimestamp(message)
    }
}
