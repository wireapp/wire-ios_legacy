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

import WireSyncEngine

final class SessionManagerLifeCycleObserver {

    // MARK: - Public Property
    var sessionManager: SessionManager?

    // MARK: - Private Property
    private var observerTokens: [Any] = []
    private var soundEventListeners = [UUID: SoundEventListener]()

    // MARK: - Initialization
    public init(sessionManager: SessionManager? = nil) {
        self.sessionManager = sessionManager
    }

    // MARK: - Public Implementation
    func createLifeCycleObserverTokens() {
        guard let createdSessionObserverToken = sessionManager?.addSessionManagerCreatedSessionObserver(self) else {
            return
        }
        observerTokens.append(createdSessionObserverToken)

        guard let destroyedSessionObserverToken = sessionManager?.addSessionManagerDestroyedSessionObserver(self) else {
            return
        }
        observerTokens.append(destroyedSessionObserverToken)
    }
}

extension SessionManagerLifeCycleObserver: SessionManagerCreatedSessionObserver, SessionManagerDestroyedSessionObserver {

    // MARK: - SessionManagerCreatedSessionObserver
    func sessionManagerCreated(userSession: ZMUserSession) {
        setSoundEventListener(for: userSession)
    }

    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) { }

    // MARK: - SessionManagerDestroyedSessionObserver
    func sessionManagerDestroyedUserSession(for accountId: UUID) {
        resetSoundEventListener(for: accountId)
    }

    // MARK: - Private Implementation
    private func setSoundEventListener(for userSession: ZMUserSession) {
        for (accountId, session) in sessionManager?.backgroundUserSessions ?? [:] where session == userSession {
            soundEventListeners[accountId] = SoundEventListener(userSession: userSession)
        }
    }

    private func resetSoundEventListener(for accountID: UUID) {
        soundEventListeners[accountID] = nil
    }
}
