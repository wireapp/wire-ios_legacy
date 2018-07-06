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
        if !showDestructionCountdown() && nil != destructionLink {
            tearDownCountdown()
            return
        }

        guard showDestructionCountdown(), let destructionDate = message.destructionDate else { return }
        let duration = destructionDate.timeIntervalSinceNow

        if !countdownView.isAnimatingProgress && duration >= 1 {
            let progress = calculateCurrentCountdownProgress()
            countdownView.startAnimating(duration: duration, currentProgress: progress)
            countdownView.isHidden = false
        }
        toolboxView.updateTimestamp(message)
    }

    func calculateCurrentCountdownProgress() -> CGFloat {
        let progress = CGFloat(1 - message.destructionDate!.timeIntervalSinceNow / message.deletionTimeout)
        return progress
    }
}

/*
- (void)updateCountdownView
    {
        self.countdownContainerViewHidden = !self.showDestructionCountdown;

        if (!self.showDestructionCountdown && nil != self.destructionLink) {
            [self tearDownCountdown];
            return;
        }

        if (!self.showDestructionCountdown || !self.message.destructionDate) {
            return;
        }

        NSTimeInterval duration = self.message.destructionDate.timeIntervalSinceNow;

        if (!self.countdownView.isAnimatingProgress && duration >= 1) {
            NSTimeInterval progress = self.calculateCurrentCountdownProgress;

            [self.countdownView startAnimatingWithDuration:duration currentProgress:progress];
            self.countdownView.hidden = NO;
        }

        [self.toolboxView updateTimestamp:self.message];
}
*/
