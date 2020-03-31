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
import SystemConfiguration
import WireUtilities
import CoreTelephony

private let zmLog = ZMSLog(tag: "NetworkStatus")

public enum ServerReachability {
    /// Backend can be reached.
    case ok
    /// Backend can not be reached.
    case unreachable
}

public protocol NetworkStatusObserver: NSObjectProtocol {
    /// note.object is the NetworkStatus instance doing the monitoring.
    /// Method name @c `-networkStatusDidChange:` conflicts with some apple internal method name.
    func wr_networkStatusDidChange(_ note: Notification)
}

extension Notification.Name {
    public static let NetworkStatus = Notification.Name("NetworkStatusNotification")
}

/// This class monitors the reachability of backend. It emits notifications to its observers if the status changes.
public final class NetworkStatus {

    private let reachabilityRef: SCNetworkReachability

    init() {
        var zeroAddress: sockaddr_in = sockaddr_in()
        bzero(&zeroAddress, MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        // Passes the reference of the struct
        guard let reachabilityRef = withUnsafePointer(to: &zeroAddress, { pointer in
            // Converts to a generic socket address
            return pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) {
                // $0 is the pointer to `sockaddr`
                return SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            fatalError("reachabilityRef can not be inited")
        }

        self.reachabilityRef = reachabilityRef

        startReachabilityObserving()
    }

    deinit {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode!.rawValue)
    }

    func startReachabilityObserving() {
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        // Sets `self` as listener object
        context.info = UnsafeMutableRawPointer(Unmanaged<NetworkStatus>.passUnretained(self).toOpaque())

        if SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context) {
            if SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode!.rawValue) {
                zmLog.info("Scheduled network reachability callback in runloop")
            } else {
                zmLog.error("Error scheduling network reachability in runloop")
            }
        } else {
            zmLog.error("Error setting network reachability callback")
        }
    }

    // MARK: - Public API

    /// The shared network status object (status of 0.0.0.0)
    static public var shared: NetworkStatus = NetworkStatus()

    /// Current state of the network.
    public var reachability: ServerReachability {
        var returnValue: ServerReachability = .unreachable
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()

        if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {

            let reachable: Bool = flags.contains(.reachable)
            let connectionRequired: Bool = flags.contains(.connectionRequired)

            switch (reachable, connectionRequired) {
            case (true, false):
                zmLog.info("Reachability status: reachable and connected.")
                returnValue = .ok
            case (true, true):
                zmLog.info("Reachability status: reachable but connection required.")
            case (false, _):
                zmLog.info("Reachability status: not reachable.")
            }

        } else {
            zmLog.info("Reachability status could not be determined.")
        }

        return returnValue
    }

    // This indicates if the network quality according to the system is at 3G level or above. On Wifi it will return YES.
    // When offline it will return NO;
    var isNetworkQualitySufficientForOnlineFeatures: Bool {

        var goodEnough = true
        var isWifi = true

        switch reachability {
        case .ok:
            // we are online, check if we are on wifi or not
            var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
            SCNetworkReachabilityGetFlags(reachabilityRef, &flags)

            isWifi = !flags.contains(.isWWAN)
        case .unreachable:
            // we are offline, so access is definitetly not good enough
            return false
        }

        if !isWifi {
            // we are online, but we determited from above that we're on radio
            let networkInfo = CTTelephonyNetworkInfo()

            let radioAccessTechnology = networkInfo.currentRadioAccessTechnology

            if (radioAccessTechnology == CTRadioAccessTechnologyGPRS) || (radioAccessTechnology == CTRadioAccessTechnologyEdge) {

                goodEnough = false
            }
        }

        return goodEnough
    }

    public var description: String {
        return "<\(type(of: self)): \(self)> Server reachability: \(stringForCurrentStatus)"
    }

    // MARK: - Utilities

    private var ReachabilityCallback: SCNetworkReachabilityCallBack? {

        let callbackClosure: SCNetworkReachabilityCallBack? = {
            (reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            guard let info = info else {
                assert(false, "info was NULL in ReachabilityCallback")

                return
            }

            let networkStatus = Unmanaged<NetworkStatus>.fromOpaque(info).takeUnretainedValue()

            // Post a notification to notify the client that the network reachability changed.
            NotificationCenter.default.post(name: Notification.Name.NetworkStatus, object: networkStatus)
        }

        return callbackClosure
    }

    var stringForCurrentStatus: String {
        switch reachability {
        case .ok:
            return "OK"
        case .unreachable:
            return "Unreachable"
        }
    }

}
