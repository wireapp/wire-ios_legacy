//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import WireDataModel
import WireTransport
import WireMessageStrategy
import WireRequestStrategy

class PushMessageHandlerDummy : NSObject, PushMessageHandler {

    func process(_ genericMessage: ZMGenericMessage) {
        // nop
    }

    func process(_ message: ZMMessage) {
        // nop
    }

    public func didFailToSend(_ message: ZMMessage) {
    // nop
    }

}


class DeliveryConfirmationDummy : NSObject, DeliveryConfirmationDelegate {

    static var sendDeliveryReceipts: Bool {
        return false
    }

    var needsToSyncMessages: Bool {
        return false
    }

    func needsToConfirmMessage(_ messageNonce: UUID) {
        // nop
    }

    func didConfirmMessage(_ messageNonce: UUID) {
        // nop
    }

}


class ClientRegistrationStatus : NSObject, ClientRegistrationDelegate {

    let context : NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var clientIsReadyForRequests: Bool {
        if let clientId = context.persistentStoreMetadata(forKey: "PersistedClientId") as? String { // TODO move constant into shared framework
            return clientId.characters.count > 0
        }

        return false
    }

    func didDetectCurrentClientDeletion() {
        // nop
    }
}


class TaskCancellationDummy: NSObject, ZMRequestCancellation {
    func cancelTask(with taskIdentifier: ZMTaskIdentifier) {}
}


enum AuthenticationState {
    case authenticated, unauthenticated
}

protocol AuthenticationStatusProvider {

    var state: AuthenticationState { get }
    
}

class AuthenticationStatus : AuthenticationStatusProvider {

    let transportSession : ZMTransportSession

    init(transportSession: ZMTransportSession) {
        self.transportSession = transportSession
    }

    var state: AuthenticationState {
        return isLoggedIn ? .authenticated : .unauthenticated
    }

    private var isLoggedIn : Bool {
        return transportSession.cookieStorage.authenticationCookieData != nil
    }

}
