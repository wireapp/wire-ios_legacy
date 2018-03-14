//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


/// Enum for section ordering in ParticipantsViewController's collection view
///
/// - user: user section (section 0)
/// - serviceUser: service user section (section 1)
public enum UserType: Int {
    case user = 0
    case serviceUser = 1
}

extension ZMConversation {

    /// returns a dictionary which key is UserType, value is sorted array of ZMBareUser
    public var sortedOtherActiveParticipantsGroupByUserType: [UserType: [ZMBareUser]] {
        guard let participants = otherActiveParticipants.array as? [ZMBareUser] else { return [:] }
        let userParticipants = participants.filter { !$0.isServiceUser }.sorted { lhs, rhs in
            lhs.displayName < rhs.displayName
        }

        let serviceUserParticipants = participants.filter { $0.isServiceUser }.sorted { lhs, rhs in
            lhs.displayName < rhs.displayName
        }

        return [.user: userParticipants,
                .serviceUser: serviceUserParticipants]
    }

}
