//
//  Hockey.swift
//  WireExtensionComponents
//
//  Created by Marco Conti on 03.05.18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import Foundation
import HockeySDK

extension BITHockeyManager {
    
    @objc public func setTrackingEnabled(_ enabled: Bool) {
        self.isMetricsManagerDisabled = !enabled
        self.isInstallTrackingDisabled = !enabled
        self.isCrashManagerDisabled = !enabled
    }
}
