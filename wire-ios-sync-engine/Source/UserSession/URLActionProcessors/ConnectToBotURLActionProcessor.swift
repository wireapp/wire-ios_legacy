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

class ConnectToBotURLActionProcessor: NSObject, URLActionProcessor {

    var transportSession: TransportSessionType
    var eventProcessor: UpdateEventProcessor
    var contextProvider: ContextProvider

    init(contextprovider: ContextProvider,
         transportSession: TransportSessionType,
         eventProcessor: UpdateEventProcessor) {
        self.contextProvider = contextprovider
        self.transportSession = transportSession
        self.eventProcessor = eventProcessor
    }

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        if case .connectBot(let serviceUserData) = urlAction {
            let serviceUser = ZMSearchUser(contextProvider: contextProvider,
                                           name: "",
                                           handle: nil,
                                           accentColor: .strongBlue,
                                           remoteIdentifier: serviceUserData.service,
                                           teamIdentifier: nil,
                                           user: nil,
                                           contact: nil)
            serviceUser.providerIdentifier = serviceUserData.provider.transportString()
            serviceUser.createConversation(transportSession: transportSession,
                                           eventProcessor: eventProcessor,
                                           contextProvider: contextProvider) { [weak delegate] (result) in

                                            if let error = result.error {
                                                delegate?.failedToPerformAction(urlAction, error: error)
                                            } else {
                                                delegate?.completedURLAction(urlAction)
                                            }
            }
        }
    }

}
