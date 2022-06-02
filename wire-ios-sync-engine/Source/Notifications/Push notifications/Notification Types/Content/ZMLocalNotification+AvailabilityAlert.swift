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

extension ZMLocalNotification {

    convenience init?(availability: AvailabilityKind, managedObjectContext moc: NSManagedObjectContext) {
        let builder = AvailabilityNotificationBuilder(availability: availability, managedObjectContext: moc)
        self.init(builder: builder, moc: moc)
    }

}

private class AvailabilityNotificationBuilder: NotificationBuilder {

    let managedObjectContext: NSManagedObjectContext
    let availability: AvailabilityKind

    init(availability: AvailabilityKind, managedObjectContext: NSManagedObjectContext) {
        self.availability = availability
        self.managedObjectContext = managedObjectContext
    }

    var notificationType: LocalNotificationType {
        return .availabilityBehaviourChangeAlert(availability)
    }

    func shouldCreateNotification() -> Bool {
        return availability.isOne(of: .away, .busy)
    }

    func titleText() -> String? {
        return notificationType.alertTitleText(team: ZMUser.selfUser(in: managedObjectContext).team)
    }

    func bodyText() -> String {
        return notificationType.alertMessageBodyText()
    }

    func userInfo() -> NotificationUserInfo? {
        return nil
    }
}
