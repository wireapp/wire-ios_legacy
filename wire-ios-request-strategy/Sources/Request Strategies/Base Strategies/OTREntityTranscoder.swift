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

open class OTREntityTranscoder<Entity: OTREntity & Hashable> : NSObject, EntityTranscoder {

    let context: NSManagedObjectContext
    let clientRegistrationDelegate: ClientRegistrationDelegate

    public init(context: NSManagedObjectContext, clientRegistrationDelegate: ClientRegistrationDelegate) {
        self.context = context
        self.clientRegistrationDelegate = clientRegistrationDelegate
    }

    open func request(forEntity entity: Entity, apiVersion: APIVersion) -> ZMTransportRequest? {
        return nil
    }

    /// If you override this method in your subclass you must call super.
    open func request(forEntity entity: Entity, didCompleteWithResponse response: ZMTransportResponse) {
         _ = entity.parseUploadResponse(response, clientRegistrationDelegate: self.clientRegistrationDelegate)
    }

    /// If you override this method in your subclass you must call super.
    open func shouldTryToResend(entity: Entity, afterFailureWithResponse response: ZMTransportResponse) -> Bool {
        return entity.parseUploadResponse(response, clientRegistrationDelegate: self.clientRegistrationDelegate).contains(.missing)
    }

}
