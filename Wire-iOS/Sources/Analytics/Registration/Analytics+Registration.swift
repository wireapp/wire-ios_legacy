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

extension Analytics {
    func tagRegistrationSucceded(context: String) {
        self.tagEvent("registration.succeeded", attributes: ["context": context])
    }

    func tagOpenedTeamCreation(context: String) {
        self.tagEvent("start.opened_team_registration", attributes: ["context": context])
    }

    enum InviteResult {
        case none
        case invited(invitesCount: Int)
    }

    func tagTeamFinishedInviteStep(with result: InviteResult) {
        let attributes: [String: Any]

        switch(result) {
        case .none:
            attributes = ["invited": false,
                          "invites:": 0]
        case .invited(let invitesCount):
            attributes = ["invited": true,
                          "invites:": invitesCount]
        }

        tagEvent("team.finished_invite_step", attributes: attributes)
    }
}
