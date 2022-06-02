//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public struct BackupMetadata: Codable {
    public enum Platform: String, Codable {
        case iOS
    }

    public let platform: Platform
    public let appVersion, modelVersion: String
    public let creationTime: Date
    public let userIdentifier: UUID
    public let clientIdentifier: String

    public init(
        appVersion: String,
        modelVersion: String,
        creationTime: Date = .init(),
        userIdentifier: UUID,
        clientIdentifier: String
        ) {
        platform = .iOS
        self.appVersion = appVersion
        self.modelVersion = modelVersion
        self.creationTime = creationTime
        self.userIdentifier = userIdentifier
        self.clientIdentifier = clientIdentifier
    }

    public init(
        userIdentifier: UUID,
        clientIdentifier: String,
        appVersionProvider: VersionProvider = Bundle.main,
        modelVersionProvider: VersionProvider = CoreDataStack.loadMessagingModel()
        ) {
        self.init(
            appVersion: appVersionProvider.version,
            modelVersion: modelVersionProvider.version,
            userIdentifier: userIdentifier,
            clientIdentifier: clientIdentifier
        )
    }
}

// MARK: - Equatable

extension BackupMetadata: Equatable {}

public func == (lhs: BackupMetadata, rhs: BackupMetadata) -> Bool {
    return lhs.platform == rhs.platform
        && lhs.appVersion == rhs.appVersion
        && lhs.modelVersion == rhs.modelVersion
        && (lhs.creationTime.timeIntervalSince1970 - rhs.creationTime.timeIntervalSince1970) < 0.001 // We only store 3 floating points
        && lhs.userIdentifier == rhs.userIdentifier
        && lhs.clientIdentifier == rhs.clientIdentifier
}

// MARK: - Serialization Helper

public extension BackupMetadata {

    func write(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.iso8601)
        let data = try encoder.encode(self)
        try data.write(to: url)
    }

    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.iso8601)
        self = try decoder.decode(type(of: self), from: data)
    }

}

private extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .usPOSIX
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

private extension Locale {
    static let usPOSIX = Locale(identifier: "en_US_POSIX")
}

// MARK: - Verification

public extension BackupMetadata {

    enum VerificationError: Error {
        case backupFromNewerAppVersion
        case userMismatch
    }

    func verify(
        using userIdentifier: UUID,
        modelVersionProvider: VersionProvider = CoreDataStack.loadMessagingModel()
        ) -> VerificationError? {
        guard self.userIdentifier == userIdentifier else { return .userMismatch }
        let current = Version(string: modelVersionProvider.version)
        let backup = Version(string: modelVersion)

        // Backup has been created on a newer app version.
        guard current >= backup else { return .backupFromNewerAppVersion }
        return nil
    }

}

// MARK: - Version Helper

public protocol VersionProvider {
    var version: String { get }
}

extension NSManagedObjectModel: VersionProvider {
    public var version: String {
        return versionIdentifiers.first as! String
    }
}

extension Bundle: VersionProvider {
    public var version: String {
        return infoDictionary!["CFBundleShortVersionString"] as! String
    }
}
