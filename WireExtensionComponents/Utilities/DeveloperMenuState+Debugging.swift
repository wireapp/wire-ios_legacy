//
//  DeveloperMenuState+Debugging.swift
//  Wire-iOS
//
//  Created by Marco Conti on 10/04/2017.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import WireSystem

extension DeveloperMenuState {
    
    public static func prepareForDebugging() {
        self.enableLogsForMessageSendingDebugging()
    }
    
    private static func enableLogsForMessageSendingDebugging() {
        ["Network", "Dependencies", "State machine"].forEach {
            ZMSLog.set(level: .debug, tag: $0)
        }
    }
}
