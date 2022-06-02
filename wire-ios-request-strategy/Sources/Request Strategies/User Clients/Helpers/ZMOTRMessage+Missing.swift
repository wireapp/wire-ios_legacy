//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel

@objc public protocol SelfClientDeletionDelegate {

    /// Invoked when the self client needs to be deleted
    func deleteSelfClient()
}

// MARK: - Missing and deleted clients
public extension ZMOTRMessage {

    @objc func parseMissingClientsResponse(_ response: ZMTransportResponse, clientRegistrationDelegate: ClientRegistrationDelegate) -> Bool {
        return self.parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate).contains(.missing)
    }

}
