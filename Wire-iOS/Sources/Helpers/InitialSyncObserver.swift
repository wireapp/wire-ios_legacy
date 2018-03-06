//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

/// Block based convenience wrapper around `ZMInitialSyncCompletionObserver`.
/// The passed in handler closure will be called immediately in case the
/// initial sync has already been completed when creating an instance and
/// will be called when the internal observer fires otherwise.
/// The `isCompleted` flag can be queried to check the current state.
final class InitialSyncObserver: NSObject, ZMInitialSyncCompletionObserver {
    private var token: Any!
    private var handler: (Bool) -> Void
    
    /// Whether the initial sync has been completed yet.
    private(set) var isCompleted = false
    
    init(in userSession: ZMUserSession, handler: @escaping (Bool) -> Void) {
        self.handler = handler
        super.init()

        // Immediately call the handler in case the initial sync has
        // already been completed, register for updates otherwise.
        if userSession.hasCompletedInitialSync {
            handleCompletedSync()
        } else {
            token = ZMUserSession.addInitialSyncCompletionObserver(self, userSession: userSession)
        }
    }
    
    private func handleCompletedSync() {
        isCompleted = true
        handler(isCompleted)
    }
    
    // MARK: - ZMInitialSyncCompletionObserver
    
    func initialSyncCompleted() {
        handleCompletedSync()
        token = nil
    }
    
}
