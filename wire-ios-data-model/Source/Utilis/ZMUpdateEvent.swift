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

extension ZMUpdateEvent {
    public var messageNonce: UUID? {
        switch type {
        case .conversationMessageAdd,
             .conversationAssetAdd,
             .conversationKnock:
            return payload.dictionary(forKey: "data")?["nonce"] as? UUID
        case .conversationClientMessageAdd,
             .conversationOtrMessageAdd,
             .conversationOtrAssetAdd:
            let message = GenericMessage(from: self)
            guard let messageID = message?.messageID else {
                return nil
            }
            return UUID(uuidString: messageID)
        default:
            return nil
        }
    }

    public var userIDs: [UUID] {
        guard let dataPayload = (payload as NSDictionary).dictionary(forKey: "data"),
            let userIds = dataPayload["user_ids"] as? [String] else {
                return []
        }
        return userIds.compactMap({ UUID.init(uuidString: $0)})
    }

    public var qualifiedUserIDs: [QualifiedID]? {
        qualifiedUserIDsFromQualifiedIDList() ?? qualifiedUserIDsFromUserList()
    }

    private func qualifiedUserIDsFromUserList() -> [QualifiedID]? {
        guard let dataPayload = (payload as NSDictionary).dictionary(forKey: "data"),
              let userDicts = dataPayload["users"] as? [NSDictionary] else {
                return nil
        }

        let qualifiedIDs: [QualifiedID] = userDicts.compactMap({
            let qualifiedID = $0.optionalDictionary(forKey: "qualified_id") as NSDictionary?

            guard
                let uuid = $0.optionalUuid(forKey: "id") ?? qualifiedID?.optionalUuid(forKey: "id"),
                let domain = qualifiedID?.string(forKey: "domain")
            else {
                return nil
            }

            return QualifiedID(uuid: uuid, domain: domain)
        })

        if !qualifiedIDs.isEmpty {
            return qualifiedIDs
        } else {
            return nil
        }
    }

    private func qualifiedUserIDsFromQualifiedIDList() -> [QualifiedID]? {
        guard let dataPayload = (payload as NSDictionary).dictionary(forKey: "data"),
              let userDicts = dataPayload["qualified_user_ids"] as? [NSDictionary] else {
                return nil
        }

        let qualifiedIDs: [QualifiedID] = userDicts.compactMap({
            guard
                let uuid = $0.uuid(forKey: "id"),
                let domain = $0.string(forKey: "domain")
            else {
                return nil
            }

            return QualifiedID(uuid: uuid, domain: domain)
        })

        if !qualifiedIDs.isEmpty {
            return qualifiedIDs
        } else {
            return nil
        }
    }

    public func users(in context: NSManagedObjectContext, createIfNeeded: Bool) -> [ZMUser] {

        if let qualifiedUserIDs = qualifiedUserIDs {
            if createIfNeeded {
                return qualifiedUserIDs.map { ZMUser.fetchOrCreate(with: $0.uuid,
                                                                   domain: $0.domain,
                                                                   in: context) }
            } else {
                return qualifiedUserIDs.compactMap { ZMUser.fetch(with: $0.uuid,
                                                                  domain: $0.domain,
                                                                  in: context) }
            }
        } else {
            if createIfNeeded {
                return userIDs.map { ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) }
            } else {
                return userIDs.compactMap { ZMUser.fetch(with: $0, domain: nil, in: context) }
            }

        }
    }

    public var participantsRemovedReason: ZMParticipantsRemovedReason {
        guard let dataPayload = (payload as NSDictionary).dictionary(forKey: "data"),
              let reasonString = dataPayload["reason"] as? String else {
            return ZMParticipantsRemovedReason.none
        }
        return ZMParticipantsRemovedReason(reasonString)
    }
}
