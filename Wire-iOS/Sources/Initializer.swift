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
import WireSyncEngine
import WireCommonComponents
import avs

// MARK: - Initializer
public protocol Initializer {
    func configure()
}

// MARK: - BackendEnvironmentInitializer
final class BackendEnvironmentInitializer: Initializer {
    public func configure() {
        guard let backendTypeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() else {
            return
        }
        AutomationHelper.sharedHelper.persistBackendTypeOverrideIfNeeded(with: backendTypeOverride)
    }
}

// MARK: - PerformanceDebuggerInitializer
final class PerformanceDebuggerInitializer: Initializer {
    public func configure() {
        PerformanceDebugger.shared.start()
    }
}

// MARK: - ZMSLogInitializer
final class ZMSLogInitializer: Initializer {
    public func configure() {
        ZMSLog.switchCurrentLogToPrevious()
    }
}

// MARK: - ZMSLogInitializer
final class AVSLoggingInitializer: Initializer {
    public func configure() {
        SessionManager.startAVSLogging()
    }
}

// MARK: - AutomationHelperInitializer
final class AutomationHelperInitializer: Initializer {
    public func configure() {
        AutomationHelper.sharedHelper.installDebugDataIfNeeded()
    }
}

// MARK: - MediaManagerInitializer
final class MediaManagerInitializer: Initializer {
    public func configure() {
        let mediaManagerLoader = MediaManagerLoader()
        mediaManagerLoader.send(message: .appStart)
    }
}

// MARK: - TrackingInitializer
final class TrackingInitializer: Initializer {
    public func configure() {
        let containsConsoleAnalytics = ProcessInfo.processInfo
            .arguments.contains(AnalyticsProviderFactory.ZMConsoleAnalyticsArgumentKey)
        
        AnalyticsProviderFactory.shared.useConsoleAnalytics = containsConsoleAnalytics
        Analytics.shared = Analytics(optedOut: TrackingManager.shared.disableAnalyticsSharing)
    }
}

// MARK: - FileBackupExcluderInitializer
final class FileBackupExcluderInitializer: Initializer {
    public func configure() {
        guard let appGroupIdentifier = Bundle.main.appGroupIdentifier else {
            return
        }
        let fileBackupExcluder = FileBackupExcluder()
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
    }
}

