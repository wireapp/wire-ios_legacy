//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
#if DATADOG_IMPORT
import Datadog
import DatadogCrashReporting
import WireTransport
import UIKit

public class DatadogWrapper {

    /// Get shared instance only if Developer Flag is on.

    public static var shared: DatadogWrapper? = {
        let bundle = Bundle(for: DatadogWrapper.self)

        guard
            let appID = bundle.infoForKey("DatadogAppId"),
            let clientToken = bundle.infoForKey("DatadogClientToken")
        else {
            print("missing Datadog appID and clientToken - logging disabled")
            return nil
        }

        return DatadogWrapper(appID: appID, clientToken: clientToken)
    }()

    /// SHA256 string to identify current Device across app and extensions.

    public var datadogUserId: String

    var logger: Logger?
    var defaultLevel: LogLevel

    private init(
        appID: String,
        clientToken: String,
        environment: BackendEnvironmentProvider = BackendEnvironment.shared,
        level: LogLevel = .debug
    ) {
        Datadog.initialize(
            appContext: .init(),
            trackingConsent: .granted,
            configuration: Datadog.Configuration
                .builderUsing(
                    rumApplicationID: appID,
                    clientToken: clientToken,
                    environment: environment.title.alphanumericString
                )
                .set(endpoint: .eu1)
                .set(tracingSamplingRate: 100)
                .set(rumSessionsSamplingRate: 100)
                .trackUIKitRUMViews()
                .trackUIKitRUMActions()
                .trackBackgroundEvents()
                .trackRUMLongTasks()
                .enableCrashReporting(using: DDCrashReportingPlugin())
                .build()
        )

        defaultLevel = level
        logger = Logger.builder
            .sendNetworkInfo(true)
            .sendLogsToDatadog(true)
            .set(loggerName: "iOS Wire App")
            .printLogsToConsole(true, usingFormat: .shortWith(prefix: "[iOS App] "))
            .set(datadogReportingThreshold: level)
            .build()

        datadogUserId = UIDevice.current.identifierForVendor?.uuidString.sha256String ?? "none"
    }

    public func startMonitoring() {
        Global.rum = RUMMonitor.initialize()
        Global.sharedTracer = Tracer.initialize(
            configuration: Tracer.Configuration(
              sendNetworkInfo: true
            )
          )
        Datadog.setUserInfo(id: datadogUserId)
        RemoteMonitoring.remoteLogger = self

        log(
            level: defaultLevel,
            message: "Datadog startMonitoring for device: \(datadogUserId)"
        )
    }

    public func log(
        level: LogLevel,
        message: String,
        error: Error? = nil,
        attributes: [String: Encodable]? = nil
    ) {
        logger?.log(
            level: level,
            message: message,
            error: error,
            attributes: attributes
        )
    }
}

extension DatadogWrapper: RemoteLogger {

    public func log(
        message: String,
        error: Error?,
        attributes: [String: Encodable]?,
        level: RemoteMonitoring.Level
    ) {
        log(
            level: level.logLevel,
            message: message,
            error: error,
            attributes: attributes
        )
    }

}

extension RemoteMonitoring.Level {

    var logLevel: LogLevel {
        switch self {
        case .debug:
            return .debug

        case .info:
            return .info

        case .notice:
            return .notice

        case .warn:
            return .warn

        case .error:
            return .error

        case .critical:
            return .critical
        }
    }
}

// MARK: - Crypto helper

import CryptoKit

extension String {

    var sha256String: String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    var alphanumericString: String {
        let pattern = "[^A-Za-z0-9]+"
        return self.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
    }
}

#else

public enum LogLevel {

    case debug
    case critical
    case info
    case warn

}
public class DatadogWrapper {

    public static let shared: DatadogWrapper? = nil

    public func log(
        level: LogLevel,
        message: String,
        error: Error? = nil,
        attributes: [String: Encodable]? = nil
    ) {}

    public func startMonitoring() {}

    public var datadogUserId: String = "NONE"
}

#endif
