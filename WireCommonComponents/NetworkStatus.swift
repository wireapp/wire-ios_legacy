
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

enum ServerReachability : Int {
    /// Backend can be reached.
    case ok
    /// Backend can not be reached.
    case unreachable
}

protocol NetworkStatusObserver: NSObjectProtocol {
    /// note.object is the NetworkStatus instance doing the monitoring.
    /// Method name @c `-networkStatusDidChange:` conflicts with some apple internal method name.
    func wr_networkStatusDidChange(_ note: Notification?)
}

extension Notification.Name {
    static let NetworkStatus = Notification.Name("NetworkStatusNotification")
}

/// This class monitors the reachability of backend. It emits notifications to its observers if the status changes.
public final class NetworkStatus: NSObject {
    
    //- (id)initWithClientInstance:(ZCClientInstance *)clientInstance;
    
    /// Current state of the network.
    func reachability() -> ServerReachability {
    }
    
    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    // This indicates if the network quality according to the system is at 3G level or above. On Wifi it will return YES.
    // When offline it will return NO;
    func isNetworkQualitySufficientForOnlineFeatures() -> Bool {
    }
    
    #endif
    func stringForCurrentStatus() -> String? {
    }
    
    class func add(_ observer: NetworkStatusObserver?) {
    }
    
    class func remove(_ observer: NetworkStatusObserver?) {
    }
    
    private let reachabilityRef: SCNetworkReachability
    
    
    /// The shared network status object (status of 0.0.0.0)
    class func shared() -> Self {
    }

    // MARK: - NSObject
    
    
    /// Returns status for specific host
    ///
    /// - Parameter hostURL: URL of the host
    init?(host hostURL: URL) {
        guard let host = hostURL.host,
              let reachabilityRef = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }

        self.reachabilityRef = reachabilityRef

        super.init()
        
        startReachabilityObserving()
    }
    
//    override init() {
//        super.init()
//        var zeroAddress: sockaddr_in
//        bzero(&zeroAddress, MemoryLayout.size(ofValue: zeroAddress))
//        zeroAddress.sin_len = MemoryLayout.size(ofValue: zeroAddress)
//        zeroAddress.sin_family = AF_INET
//        #if !__clang_analyzer__
//        reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, &zeroAddress as? sockaddr)
//        #endif
//        startReachabilityObserving()
//    }
    
    deinit {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode!.rawValue)
    }
    
    func startReachabilityObserving() {
            var context = SCNetworkReachabilityContext(0, (self), nil, nil, nil)
            
            if SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context) {
                if SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode) {
                    ZMLogInfo("Scheduled network reachability callback in runloop")
                } else {
                    ZMLogError("Error scheduling network reachability in runloop")
                }
            } else {
                ZMLogError("Error setting network reachability callback")
            }
    }


    // MARK: - Public API
    class func status(forHost hostURL: URL?) -> Self {
        let status = NetworkStatus(host: hostURL)
        return status
    }
    
    static let sharedStatusSingleton: NetworkStatus? = {
        var singleton = self.init()
        return singleton
    }()
    
    class func sharedStatus() -> Self {
        // `dispatch_once()` call was converted to a static variable initializer
        return sharedStatusSingleton
    }
    
    func reachability() -> ServerReachability {
        assert(reachabilityRef != nil, "reachability getter called with NULL reachabilityRef")
        var returnValue = ServerReachabilityUnreachable as? ServerReachability
        var flags: SCNetworkReachabilityFlags
        
        if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {
            
            let reachable = (flags.rawValue & SCNetworkReachabilityFlags.reachable.rawValue)
            let connectionRequired = (flags.rawValue & SCNetworkReachabilityFlags.connectionRequired.rawValue)
            
            if reachable && !connectionRequired {
                ZMLogInfo("Reachability status: reachable and connected.")
                returnValue = ServerReachabilityOK
            } else if reachable && connectionRequired {
                ZMLogInfo("Reachability status: reachable but connection required.")
            } else {
                ZMLogInfo("Reachability status: not reachable.")
            }
        } else {
            ZMLogInfo("Reachability status could not be determined.")
        }
        return returnValue!
    }
    class func add(_ observer: NetworkStatusObserver?) {
        // Make sure that we have an actual instance doing the monitoring, whenever someone asks for it
        self.sharedStatus()
        
        if let observer = observer {
            NotificationCenter.default.addObserver(observer, selector: #selector(wr_networkStatusDidChange(_:)), name: NetworkStatusNotificationName, object: nil)
        }
    }
    
    class func remove(_ observer: NetworkStatusObserver?) {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer, name: NetworkStatusNotificationName, object: nil)
        }
    }
    
//    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    ///TODO: extension?
    func isNetworkQualitySufficientForOnlineFeatures() -> Bool {
        
        var goodEnough = true
        var isWifi = true
        
        if reachability == ServerReachabilityOK {
            // we are online, check if we are on wifi or not
            var flags: SCNetworkReachabilityFlags
            SCNetworkReachabilityGetFlags(reachabilityRef, &flags)
            
            isWifi = !(flags.rawValue & SCNetworkReachabilityFlags.isWWAN.rawValue)
        } else {
            // we are offline, so access is definitetly not good enough
            goodEnough = false
            return goodEnough
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

    func description() -> String? {
        return String(format: "<%@: %p> Server reachability: %@", type(of: self), self, stringForCurrentStatus() ?? "")
    }
    
    // MARK: - Utilities
    private func ReachabilityCallback(_ target: SCNetworkReachability?,
                                      _ flags: SCNetworkReachabilityFlags,
                                      _ info: UnsafeMutableRawPointer?) {
        //#pragma unused (target, flags)
        assert(info != nil, "info was NULL in ReachabilityCallback")
        assert(info is NetworkStatus, "info was wrong class in ReachabilityCallback")
        
        let noteObject = info as? NetworkStatus
        // Post a notification to notify the client that the network reachability changed.
        
        NotificationCenter.default.post(name: NetworkStatusNotificationName, object: noteObject)
    }
    
    
    func stringForCurrentStatus() -> String? {
        if reachability == ServerReachabilityOK {
            return "OK"
        }
        return "Unreachable"
    }

}

/// Convenience shortcut
@inline(__always) private func IsNetworkReachable() -> Bool {
    return NetworkStatus.shared().reachability() == .ok
}


