//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMUser {

    /// Underlying storage of the analytics identifier.

    @NSManaged private var primitiveAnalyticsIdentifier: String?

    /// The analytics identifier used for tag analytic events.
    ///
    /// This identifier should only exist for the self user and only if they are a team member.
    /// A new identifier will be automatically generated the very first time this is accessed.

    @objc
    public internal(set) var analyticsIdentifier: String? {
        get {
            guard isSelfUser && isTeamMember else { return nil }

            willAccessValue(forKey: #keyPath(analyticsIdentifier))
            let value = primitiveAnalyticsIdentifier
            didAccessValue(forKey: #keyPath(analyticsIdentifier))

            if let value = value {
                return value
            } else {
                let identifier = UUID()
                let identifierString = identifier.transportString()
                self.analyticsIdentifier = identifierString
                broadcast(identifier: identifier)
                return identifierString
            }
        }

        set {
            willChangeValue(forKey: #keyPath(analyticsIdentifier))
            primitiveAnalyticsIdentifier = newValue
            didChangeValue(forKey: #keyPath(analyticsIdentifier))
        }
    }

    private func broadcast(identifier: UUID) {
        guard let moc = managedObjectContext else { return }
        let message = GenericMessage(content: DataTransfer(trackingIdentifier: identifier))
        _ = try? ZMConversation.appendMessageToSelfConversation(message, in: moc)
    }

}
