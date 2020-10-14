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

class SessionManagerLifeCycleObserver: SessionManagerCreatedSessionObserver, SessionManagerDestroyedSessionObserver {
    
    // MARK: - Private Property
    private var soundEventListeners = [UUID: SoundEventListener]()
    
    // MARK: - SessionManagerCreatedSessionObserver
    func sessionManagerCreated(userSession: ZMUserSession) {
        setSoundEventListener(for: userSession)
        enableEncryptMessagesAtRest(for: userSession)
    }

    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession) { }

    // MARK: - SessionManagerDestroyedSessionObserver
    func sessionManagerDestroyedUserSession(for accountId: UUID) {
        resetSoundEventListener(for: accountId)
    }
    
    // MARK: - Private Implementation
    private func setSoundEventListener(for userSession: ZMUserSession) {
        for (accountId, session) in SessionManager.shared?.backgroundUserSessions ?? [:] {
            if session == userSession {
                soundEventListeners[accountId] = SoundEventListener(userSession: userSession)
            }
        }
    }
    
    private func enableEncryptMessagesAtRest(for userSession: ZMUserSession) {
        guard
            SecurityFlags.forceEncryptionAtRest.isEnabled,
            userSession.encryptMessagesAtRest == false
        else {
            return
        }
        
        userSession.encryptMessagesAtRest = true
    }
    
    private func resetSoundEventListener(for accountID: UUID) {
        soundEventListeners[accountID] = nil
    }
}

