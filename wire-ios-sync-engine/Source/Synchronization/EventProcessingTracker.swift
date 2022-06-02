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
import WireDataModel

@objc public protocol EventProcessingTrackerProtocol: AnyObject {
    func registerEventProcessed()
    func registerDataInsertionPerformed(amount: UInt)
    func registerDataUpdatePerformed(amount: UInt)
    func registerDataDeletionPerformed(amount: UInt)
    func registerSavePerformed()
    func persistedAttributes(for event: String) -> [String: NSObject]
    var debugDescription: String { get }
}

@objc public class EventProcessingTracker: NSObject, EventProcessingTrackerProtocol {

    var eventAttributes = [String: [String: NSObject]]()
    public let eventName = "event.processing"

    enum Attributes: String {
        case processedEvents
        case dataDeletionPerformed
        case dataInsertionPerformed
        case dataUpdatePerformed
        case savesPerformed

        var identifier: String {
            return "event_" + rawValue
        }
    }

    private let isolationQueue = DispatchQueue(label: "EventProcessing")

    public override init() {
        super.init()
    }

    public func registerEventProcessed() {
        increment(attribute: .processedEvents)
    }

    public func registerSavePerformed() {
        increment(attribute: .savesPerformed)
    }

    public func registerDataInsertionPerformed(amount: UInt = 1) {
        increment(attribute: .dataInsertionPerformed)
    }

    public func registerDataUpdatePerformed(amount: UInt = 1) {
        increment(attribute: .dataUpdatePerformed)
    }

    public func registerDataDeletionPerformed(amount: UInt = 1) {
        increment(attribute: .dataDeletionPerformed)
    }

    private func increment(attribute: Attributes, by amount: Int = 1) {
        isolationQueue.sync {
            var currentAttributes = persistedAttributes(for: eventName)
            var value = (currentAttributes[attribute.identifier] as? Int) ?? 0
            value += amount
            currentAttributes[attribute.identifier] = value as NSObject
            setPersistedAttributes(currentAttributes, for: eventName)
        }
    }

    private func save(attribute: Attributes, value: Int) {
        isolationQueue.sync {
            var currentAttributes = persistedAttributes(for: eventName)
            var currentValue = (currentAttributes[attribute.identifier] as? Int) ?? 0
            currentValue = value
            currentAttributes[attribute.identifier] = currentValue as NSObject
            setPersistedAttributes(currentAttributes, for: eventName)
        }
    }

    public func dispatchEvent() {
        isolationQueue.sync {
            let attributes = persistedAttributes(for: eventName)
            if !attributes.isEmpty {
                setPersistedAttributes(nil, for: eventName)
            }
        }
    }

    private func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        if let attributes = attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
    }

    public func persistedAttributes(for event: String) -> [String: NSObject] {
        return eventAttributes[event] ?? [:]
    }

    override public var debugDescription: String {
        let description = isolationQueue.sync {
            "\(persistedAttributes(for: eventName))"
        }

        return description
    }
}
