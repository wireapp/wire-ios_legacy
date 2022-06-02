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

/// URLActionProcessor has the capabillity of processing a URLAction

protocol URLActionProcessor {

    /// Process an URL action
    ///
    /// - parameter urlAction: URLAction to process.
    /// - parameter delegate: Delegate which observes the attempt of processing the action.
    func process(urlAction: URLAction, delegate: PresentationDelegate?)

}

extension SessionManager {

    /// React to the application being opened via a URL
    ///
    /// - parameter url: URL the application was launched with
    /// - parameter options: options associated with the URL
    @discardableResult
    public func openURL(_ url: URL) throws -> Bool {
        guard let action = try URLAction(url: url) else { return false }

        guard action.requiresAuthentication else {
            if canProcessUrlAction {
                process(urlAction: action, on: activeUnauthenticatedSession)
            } else {
                pendingURLAction = action
            }

            return true
        }

        guard isSelectedAccountAuthenticated else {
            throw DeepLinkRequestError.notLoggedIn
        }

        guard let userSession = activeUserSession, !userSession.isLocked else {
            pendingURLAction = action
            return true
        }

        process(urlAction: action, on: userSession)
        return true
    }

    func process(urlAction action: URLAction, on processor: URLActionProcessor) {
        presentationDelegate?.shouldPerformAction(action, decisionHandler: { [weak self] (shouldPerformAction) in
            guard shouldPerformAction, let strongSelf = self else { return }
            processor.process(urlAction: action, delegate: strongSelf.presentationDelegate)
        })
    }

    public func processPendingURLActionRequiresAuthentication() {
        if let action = pendingURLAction, action.requiresAuthentication,
           let userSession = activeUserSession {
            process(urlAction: action, on: userSession)
            pendingURLAction = nil
        }
    }

    public func processPendingURLActionDoesNotRequireAuthentication() {
        if let action = pendingURLAction, !action.requiresAuthentication {
            process(urlAction: action, on: activeUnauthenticatedSession)
            pendingURLAction = nil
        }
    }

    var canProcessUrlAction: Bool {
        guard let delegate = delegate else {
            return false
        }
        return delegate.isInAuthenticatedAppState || delegate.isInUnathenticatedAppState
    }

}
