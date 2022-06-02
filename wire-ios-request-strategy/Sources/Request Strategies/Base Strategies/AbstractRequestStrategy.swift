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

import Foundation

private let zmLog = ZMSLog(tag: "Request Configuration")

@objcMembers open class AbstractRequestStrategy: NSObject, RequestStrategy {

    weak public var applicationStatus: ApplicationStatus?

    public let managedObjectContext: NSManagedObjectContext
    public var configuration: ZMStrategyConfigurationOption = [
        .allowsRequestsWhileOnline
    ]

    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        self.managedObjectContext = managedObjectContext
        self.applicationStatus = applicationStatus

        super.init()
    }

    /// Subclasses should override this method. 
    open func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        fatal("you must override this method")
    }

    open func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let applicationStatus = self.applicationStatus else {
            zmLog.error("applicationStatus is missing")
            return nil
        }

        let prerequisites = AbstractRequestStrategy.prerequisites(forApplicationStatus: applicationStatus)

        if prerequisites.isSubset(of: configuration) {
            return nextRequestIfAllowed(for: apiVersion)
        } else {
            zmLog.debug("Not performing requests since option: \(prerequisites.subtracting(configuration)) is not configured for (\(String(describing: type(of: self))))")
        }

        return nil
    }

    public class func prerequisites(forApplicationStatus applicationStatus: ApplicationStatus) -> ZMStrategyConfigurationOption {
        var prerequisites: ZMStrategyConfigurationOption = []

        if applicationStatus.synchronizationState == .unauthenticated {
            prerequisites.insert(.allowsRequestsWhileUnauthenticated)
        }

        if applicationStatus.synchronizationState == .slowSyncing {
            prerequisites.insert(.allowsRequestsDuringSlowSync)
        }

        if applicationStatus.synchronizationState == .establishingWebsocket {
            prerequisites.insert(.allowsRequestsWhileWaitingForWebsocket)
        }

        if applicationStatus.synchronizationState == .quickSyncing {
            prerequisites.insert(.allowsRequestsDuringQuickSync)
        }

        if applicationStatus.synchronizationState == .online {
            prerequisites.insert(.allowsRequestsWhileOnline)
        }

        if applicationStatus.operationState == .background {
            prerequisites.insert(.allowsRequestsWhileInBackground)
        }

        return prerequisites
    }

}
