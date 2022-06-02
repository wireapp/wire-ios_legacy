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

extension Label: ObjectInSnapshot {

    static public var observableKeys: Set<String> {
        return [
            #keyPath(Label.name), #keyPath(Label.markedForDeletion), #keyPath(Label.conversations)
        ]
    }

    public var notificationName: Notification.Name {
        return .LabelChange
    }

}

@objcMembers public class LabelChangeInfo: ObjectChangeInfo {

    public let label: LabelType

    static func changeInfo(for label: Label, changes: Changes) -> LabelChangeInfo? {
        return LabelChangeInfo(object: label, changes: changes)
    }

    public required init(object: NSObject) {
        self.label = object as! Label
        super.init(object: object)
    }

    public var nameChanged: Bool {
        return changedKeys.contains(#keyPath(Label.name))
    }

    public var markedForDeletion: Bool {
        return changedKeys.contains(#keyPath(Label.markedForDeletion))
    }

    public var conversationsChanged: Bool {
        return changedKeys.contains(#keyPath(Label.conversations))
    }

}

@objc public protocol LabelObserver: NSObjectProtocol {
    func labelDidChange(_ changeInfo: LabelChangeInfo)
}

// MARK: Registering Label observers

extension LabelChangeInfo {

    /// Adds an observer for a label
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addTeamObserver:forTeam:)
    public static func add(observer: LabelObserver, for label: LabelType) -> NSObjectProtocol? {
        guard let label = label as? Label else { return nil }
        return add(observer: observer, for: label, managedObjectContext: label.managedObjectContext!)
    }

    /// Adds an observer for the label if one is specified or to all labels is none is specified
    ///
    /// You must hold on to the token and use it to unregister
    @objc(addTeamObserver:forTeam:managedObjectContext:)
    public static func add(observer: LabelObserver, for label: LabelType?, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .LabelChange, managedObjectContext: managedObjectContext, object: label) { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? LabelChangeInfo
                else { return }

            observer.labelDidChange(changeInfo)
        }
    }

}
