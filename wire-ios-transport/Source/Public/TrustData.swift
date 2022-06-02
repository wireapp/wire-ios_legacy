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

struct TrustData: Decodable {
    struct Host: Decodable {
        enum Rule: String, Decodable {
            case endsWith = "ends_with"
            case equals
        }
        let rule: Rule
        let value: String
    }
    let certificateKey: SecKey
    let hosts: [Host]
    
    enum CodingKeys : String, CodingKey {
        case certificateKey
        case hosts
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let certificateKeyData = try container.decode(Data.self, forKey: .certificateKey)
        
        guard let certificate = SecCertificateCreateWithData(nil, certificateKeyData as CFData) else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.certificateKey, in: container, debugDescription: "Error decoding certificate for pinned key")
        }
        
        guard let certificateKey = SecCertificateCopyKey(certificate) else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.certificateKey, in: container, debugDescription: "Error extracting pinned key from certificate")
        }
        self.certificateKey = certificateKey
        self.hosts = try container.decode([TrustData.Host].self, forKey: .hosts)
    }
}

extension TrustData {
    func matches(host: String) -> Bool {
        let matchingHosts = hosts.filter { $0.matches(host: host) }
        return !matchingHosts.isEmpty
    }    
}

extension TrustData.Host {
    func matches(host: String) -> Bool {
        switch rule {
        case .endsWith:
            return host.hasSuffix(value)
        case .equals:
            return host == value
        }
    }
}

