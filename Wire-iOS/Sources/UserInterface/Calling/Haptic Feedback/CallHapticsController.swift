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

final class CallHapticsController {
    
    private lazy var hapticGenerator: CallHapticsGeneratorType? = {
        guard #available(iOS 10, *) else { return nil }
        return CallHapticsGenerator()
    }()

    private var lastCallState: CallState?
    private var participants = Set<UUID>()
    private var videoStates = [UUID: Bool]()
    
    func updateParticipants(_ newParticipants: [(UUID, CallParticipantState)]) {
        let newParticipantIdentifiers = newParticipants.map { $0.0 }
        updateParticipantsList(newParticipantIdentifiers)
        updateParticipantsVideoStateList(newParticipants)
    }
    
    func updateCallState(_ newCallState: CallState) {
        defer { lastCallState = newCallState }
        guard let oldCallState = lastCallState, oldCallState != newCallState else { return }
        
        if !oldCallState.isEnding && newCallState.isEnding {
            hapticGenerator?.trigger(event: .end)
        }
        if !oldCallState.isEstablished && newCallState.isEstablished {
            hapticGenerator?.trigger(event: .start)
        }
    }
    
    // MARK: - Private
    
    private func updateParticipantsList(_ newParticipants: [UUID]) {
        let updated = Set(newParticipants)
        let removed = !participants.subtracting(updated).isEmpty
        let added = !updated.subtracting(participants).isEmpty
        
        if removed {
            hapticGenerator?.trigger(event: .leave)
        }
        if added {
            hapticGenerator?.trigger(event: .join)
        }
        
        participants = updated
    }
    
    private func updateParticipantsVideoStateList(_ newParticipants: [(UUID, CallParticipantState)]) {
        let newVideoStates = createVideoStateMap(using: newParticipants)
        for (uuid, wasSending) in videoStates {
            if let isSending = newVideoStates[uuid], isSending != wasSending {
                hapticGenerator?.trigger(event: .toggleVideo)
            }
        }
        videoStates = newVideoStates
    }
    
    private func createVideoStateMap(using participants: [(UUID, CallParticipantState)]) -> [UUID: Bool] {
        return Dictionary(uniqueKeysWithValues: participants.map {
            ($0.0, $0.1.isSendingVideo)
        })
    }
}


// MARK - Helper

fileprivate extension CallState {
    var isEstablished: Bool {
        guard case .established = self else { return false }
        return true
    }
    
    var isEnding: Bool {
        guard case .terminating = self else { return false }
        return true
    }
}
