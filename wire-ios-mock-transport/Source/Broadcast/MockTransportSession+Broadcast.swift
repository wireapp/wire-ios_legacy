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
import WireProtos

extension MockTransportSession {

    // POST /broadcast/otr/messages
    @objc public func processBroascastOTRMessageToConversation(protobuffData data: Data, query: [String: Any], apiVersion: APIVersion) -> ZMTransportResponse {
        guard
            let otrMetaData = try? Proteus_NewOtrMessage(serializedData: data),
            let senderClient = otrMessageSender(fromClientId: otrMetaData.sender) else {
                return ZMTransportResponse(payload: nil, httpStatus: 404, transportSessionError: nil, apiVersion: apiVersion.rawValue)
        }
        
        let onlyForUser = query["report_missing"] as? String
        let missedClients = self.missedClients(fromRecipients: otrMetaData.recipients, sender: senderClient, onlyForUserId: onlyForUser)
        let deletedClients = self.deletedClients(fromRecipients: otrMetaData.recipients)
        
        let payload: [String : Any] = [
            "missing": missedClients,
            "deleted": deletedClients,
            "time": Date().transportString()
        ]
        
        let statusCode = missedClients.isEmpty ? 201 : 412
        
        return ZMTransportResponse(payload: payload as ZMTransportData, httpStatus: statusCode, transportSessionError: nil, apiVersion: apiVersion.rawValue)
    }
}
