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

import Foundation

public enum EnvironmentType: Equatable {
    case production
    case staging
    case qaDemo
    case qaDemo2
    case anta
    case bella
    case chala
    case custom(url: URL)

    var stringValue: String {
        switch self {
        case .production:
            return "production"
        case .staging:
            return "staging"
        case .qaDemo:
            return "qa-demo"
        case .qaDemo2:
            return "qa-demo-2"
        case .anta:
            return "anta"
        case .bella:
            return "bella"
        case .chala:
            return "chala"
        case .custom(url: let url):
            return "custom-\(url.absoluteString)"
        }
    }

    public init(stringValue: String) {
        switch stringValue {
        case EnvironmentType.staging.stringValue:
            self = .staging
        case EnvironmentType.qaDemo.stringValue:
            self = .qaDemo
        case EnvironmentType.qaDemo2.stringValue:
            self = .qaDemo2
        case EnvironmentType.anta.stringValue:
            self = .anta
        case EnvironmentType.bella.stringValue:
            self = .bella
        case EnvironmentType.chala.stringValue:
            self = .chala
        case let value where value.hasPrefix("custom-"):
            let urlString = value.dropFirst("custom-".count)
            if let url = URL(string: String(urlString)) {
                self = .custom(url: url)
            } else {
                self = .production
            }
        default:
            self = .production
        }
    }
}

extension EnvironmentType {
    static let defaultsKey = "ZMBackendEnvironmentType"
    
    public init(userDefaults: UserDefaults) {
        if let value = userDefaults.string(forKey: EnvironmentType.defaultsKey) {
            self.init(stringValue: value)
        } else {
            Logging.backendEnvironment.error("Could not load environment type from user defaults, falling back to production")
            self = .production
        }
    }
    
    public func save(in userDefaults: UserDefaults) {
        userDefaults.setValue(self.stringValue, forKey: EnvironmentType.defaultsKey)
    }
}

public class BackendEnvironment: NSObject {
    public let title: String
    let endpoints: BackendEndpointsProvider
    let certificateTrust: BackendTrustProvider
    let type: EnvironmentType
    
    init(title: String, environmentType: EnvironmentType, endpoints: BackendEndpointsProvider, certificateTrust: BackendTrustProvider) {
        self.title = title
        self.type = environmentType
        self.endpoints = endpoints
        self.certificateTrust = certificateTrust
    }
    
    convenience init?(environmentType: EnvironmentType, data: Data) {
        struct SerializedData: Decodable {
            let title: String
            let endpoints: BackendEndpoints
            let pinnedKeys: [TrustData]?
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let backendData = try decoder.decode(SerializedData.self, from: data)
            let pinnedKeys = backendData.pinnedKeys ?? []
            let certificateTrust = ServerCertificateTrust(trustData: pinnedKeys)
            self.init(title: backendData.title, environmentType: environmentType, endpoints: backendData.endpoints, certificateTrust: certificateTrust)
        } catch {
            Logging.backendEnvironment.error("Could not decode information from data: \(error)")
            return nil
        }
    }    
}

extension BackendEnvironment: BackendEnvironmentProvider {
    public var environmentType: EnvironmentTypeProvider {
        return EnvironmentTypeProvider(environmentType: type)
    }
    
    public var backendURL: URL {
        return endpoints.backendURL
    }
    
    public var backendWSURL: URL {
        return endpoints.backendWSURL
    }
    
    public var blackListURL: URL {
        return endpoints.blackListURL
    }
    
    public var teamsURL: URL {
        return endpoints.teamsURL
    }
    
    public var accountsURL: URL {
        return endpoints.accountsURL
    }
    
    public var websiteURL: URL {
        return endpoints.websiteURL
    }

    public var countlyURL: URL? {
        return endpoints.countlyURL
    }

    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        return certificateTrust.verifyServerTrust(trust: trust, host: host)
    }
}
