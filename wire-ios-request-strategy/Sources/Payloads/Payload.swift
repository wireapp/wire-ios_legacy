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

enum Payload {

    typealias UserClients = [Payload.UserClient]
    typealias UserClientByUserID = [String: UserClients]
    typealias UserClientByDomain = [String: UserClientByUserID]
    typealias PrekeyByClientID = [String: Prekey?]
    typealias PrekeyByUserID = [String: PrekeyByClientID]
    typealias PrekeyByQualifiedUserID = [String: PrekeyByUserID]
    typealias ClientList = [String]
    typealias ClientListByUserID = [String: ClientList]
    typealias ClientListByQualifiedUserID = [String: ClientListByUserID]
    typealias UserProfiles = [Payload.UserProfile]

    struct EventContainer<T: Codable>: Codable {
        enum CodingKeys: String, CodingKey {
            case event
        }

        let event: T
    }

    struct QualifiedUserIDList: Codable, Hashable {

        enum CodingKeys: String, CodingKey {
            case qualifiedIDs = "qualified_ids"
        }

        var qualifiedIDs: [QualifiedID]
    }

    struct Prekey: Codable {
        let key: String
        let id: Int?
    }

    struct Location: Codable {

        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitide = "lat"
        }

        let longitude: Double
        let latitide: Double
    }

    struct UserClient: Codable {

        enum CodingKeys: String, CodingKey {
            case id
            case type
            case creationDate = "time"
            case label
            case location
            case deviceClass = "class"
            case deviceModel = "model"
        }

        let id: String
        let type: String?
        let creationDate: Date?
        let label: String?
        let location: Location?
        let deviceClass: String?
        let deviceModel: String?

        init(id: String,
             deviceClass: String,
             type: String? = nil,
             creationDate: Date? = nil,
             label: String? = nil,
             location: Location? = nil,
             deviceModel: String? = nil) {
            self.id = id
            self.type = type
            self.creationDate = creationDate
            self.label = label
            self.location = location
            self.deviceClass = deviceClass
            self.deviceModel = deviceModel
        }

    }

    struct Asset: Codable {

        enum AssetSize: String, Codable {
            case preview
            case complete
        }

        enum AssetType: String, Codable {
            case image
        }

        let key: String
        let size: AssetSize
        let type: AssetType
    }

    struct ServiceID: Codable {
        let id: UUID
        let provider: UUID
    }

    struct SSOID: Codable {

        enum CodingKeys: String, CodingKey {
            case tenant
            case subject
            case scimExternalID = "scim_external_id"
        }

        let tenant: String?
        let subject: String?
        let scimExternalID: String?
    }

    enum LegalholdStatus: String, Codable {
        case enabled
        case pending
        case disabled
        case noConsent = "no_consent"
    }

    struct UserProfile: Codable {

        enum CodingKeys: String, CodingKey, CaseIterable {
            case id
            case qualifiedID = "qualified_id"
            case teamID = "team"
            case serviceID = "service"
            case SSOID = "sso_id"
            case name
            case handle
            case phone
            case email
            case assets
            case managedBy = "managed_by"
            case accentColor = "accent_id"
            case isDeleted = "deleted"
            case expiresAt = "expires_at"
            case legalholdStatus = "legalhold_status"
        }

        let id: UUID?
        let qualifiedID: QualifiedID?
        let teamID: UUID?
        let serviceID: ServiceID?
        let SSOID: SSOID?
        let name: String?
        let handle: String?
        let phone: String?
        let email: String?
        let assets: [Asset]?
        let managedBy: String?
        let accentColor: Int?
        let isDeleted: Bool?
        let expiresAt: Date?
        let legalholdStatus: LegalholdStatus?

        /// All keys which were present in the original payload even if they
        /// contained a null value.
        ///
        /// This is used to distinguish when a delta user profile update does not
        /// contain a field from when it sets the field to nil.
        let updatedKeys: Set<CodingKeys>

        init(id: UUID? = nil,
             qualifiedID: QualifiedID? = nil,
             teamID: UUID? = nil,
             serviceID: ServiceID? = nil,
             SSOID: SSOID? = nil,
             name: String? = nil,
             handle: String? = nil,
             phone: String? = nil,
             email: String? = nil,
             assets: [Asset] = [],
             managedBy: String? = nil,
             accentColor: Int? = nil,
             isDeleted: Bool? = nil,
             expiresAt: Date? = nil,
             legalholdStatus: LegalholdStatus? = nil,
             updatedKeys: Set<CodingKeys>? = nil) {

            self.id = id
            self.qualifiedID = qualifiedID
            self.teamID = teamID
            self.serviceID = serviceID
            self.SSOID = SSOID
            self.name = name
            self.handle = handle
            self.phone = phone
            self.email = email
            self.assets = assets
            self.managedBy = managedBy
            self.accentColor = accentColor
            self.isDeleted = isDeleted
            self.expiresAt = expiresAt
            self.legalholdStatus = legalholdStatus
            self.updatedKeys = updatedKeys ?? Set(CodingKeys.allCases)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
            self.qualifiedID = try container.decodeIfPresent(QualifiedID.self, forKey: .qualifiedID)
            self.teamID = try container.decodeIfPresent(UUID.self, forKey: .teamID)
            self.serviceID = try container.decodeIfPresent(ServiceID.self, forKey: .serviceID)
            self.SSOID = try container.decodeIfPresent(Payload.SSOID.self, forKey: .SSOID)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.handle = try container.decodeIfPresent(String.self, forKey: .handle)
            self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
            self.email = try container.decodeIfPresent(String.self, forKey: .email)
            self.assets = try container.decodeIfPresent([Payload.Asset].self, forKey: .assets)
            self.managedBy = try container.decodeIfPresent(String.self, forKey: .managedBy)
            self.accentColor = try container.decodeIfPresent(Int.self, forKey: .accentColor)
            self.isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted)
            self.expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
            self.legalholdStatus = try container.decodeIfPresent(LegalholdStatus.self, forKey: .legalholdStatus)
            self.updatedKeys = Set(container.allKeys)
        }
    }

    struct ResponseFailure: Codable {

        enum Label: String, Codable {
            case notFound = "not-found"
            case noEndpoint = "no-endpoint"
            case noIdentity = "no-identity"
            case unknownClient = "unknown-client"
            case missingLegalholdConsent = "missing-legalhold-consent"
            case notConnected = "not-connected"
            case connectionLimit = "connection-limit"
            case unknown

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let label = try container.decode(String.self)
                self = Label(rawValue: label) ?? .unknown
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(self.rawValue)
            }
        }

        let code: Int
        let label: Label
        let message: String

    }

    struct MessageSendingStatus: Codable {

        enum CodingKeys: String, CodingKey {
            case time
            case missing
            case redundant
            case deleted
            case failedToSend = "failed_to_send"
        }

        /// Time of sending message.
        let time: Date

        /// Clients that the message should have been encrypted for, but wasn't.
        let missing: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but isn't necessary. For
        /// example for a client who's user has been removed from the conversation.
        let redundant: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but has since been deleted.
        let deleted: ClientListByQualifiedUserID

        /// When a message is partially sent contains the list of clients which
        /// didn't receive the message.
        let failedToSend: ClientListByQualifiedUserID
    }

    struct PaginationStatus: Codable {

        enum CodingKeys: String, CodingKey {
            case pagingState = "paging_state"
            case size
        }

        let pagingState: String?
        let size: Int?

        init(pagingState: String?, size: Int) {
            self.pagingState = pagingState?.isEmpty == true ? nil : pagingState
            self.size = size
        }
    }

}
