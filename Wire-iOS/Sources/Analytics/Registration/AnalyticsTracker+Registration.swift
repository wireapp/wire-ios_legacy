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

extension AnalyticsTracker {
    func tagOpenedLandingScreen() {
        self.tagEvent("start.opened_start_screen")
    }
    
    func tagOpenedUserRegistration() {
        self.tagEvent("start.opened_person_registration")
    }
    
    func tagOpenedTeamCreation() {
        self.tagEvent("start.opened_team_registration")
    }
    
    func tagOpenedLogin() {
        self.tagEvent("start.opened_login")
    }
    
    func tagTeamCreationEmailVerified() {
        self.tagEvent("team.verified")
    }
    
    func tagTeamCreationAcceptedTerms() {
        self.tagEvent("team.accepted_terms")
    }
    
    func tagTeamCreated() {
        self.tagEvent("team.created")
    }
    
    enum InviteResult {
        case none
        case invited(invitesCount: Int)
    }
    
    func tagTeamFinishedInviteStep(with result: InviteResult) {
        let attributes: [AnyHashable: Any]
        
        switch(result) {
        case .none:
            attributes = ["invited": false,
                          "invites:": 0]
        case .invited(let invitesCount):
            attributes = ["invited": true,
                          "invites:": invitesCount]
        }
        
        self.tagEvent("team.finished_invite_step", attributes: attributes)
    }
}
