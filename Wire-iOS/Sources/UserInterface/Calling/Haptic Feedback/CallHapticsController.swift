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

import WireSyncEngine

final class CallHapticsController {

    private var lastCallState: CallState?
    private var participants = Set<CallParticipant>()
    private var videoStates = [CallParticipant: Bool]()
    private let hapticGenerator: CallHapticsGeneratorType

    init(hapticGenerator: CallHapticsGeneratorType = CallHapticsGenerator()) {
        self.hapticGenerator = hapticGenerator
    }

    func updateParticipants(_ newParticipants: [CallParticipant]) {
        updateParticipantsList(newParticipants)
        updateParticipantsVideoStateList(newParticipants)
    }

    func updateCallState(_ newCallState: CallState) {
        defer { lastCallState = newCallState }
        guard lastCallState != newCallState else { return }

        if (false == lastCallState?.isEnding || nil == lastCallState) && newCallState.isEnding {
            Log.haptics.debug("triggering end event")
            hapticGenerator.trigger(event: .end)
        }
        if (false == lastCallState?.isEstablished || nil == lastCallState) && newCallState.isEstablished {
            Log.haptics.debug("triggering start event")
            hapticGenerator.trigger(event: .start)
        }
    }

    // MARK: - Private

    private func updateParticipantsList(_ newParticipants: [CallParticipant]) {
        let updatedHashes = Set(newParticipants.map(\.hashValue))
        let participantsHashes = Set(participants.map(\.hashValue))

        let removed = !participantsHashes.subtracting(updatedHashes).isEmpty
        let added = !updatedHashes.subtracting(participantsHashes).isEmpty

        Log.haptics.debug("updating participants list: \(newParticipants), old: \(participants)")

        if removed {
            Log.haptics.debug("triggering leave event")
            hapticGenerator.trigger(event: .leave)
        }
        if added {
            Log.haptics.debug("triggering join event")
            hapticGenerator.trigger(event: .join)
        }

        participants = Set(newParticipants)
    }

    private func updateParticipantsVideoStateList(_ newParticipants: [CallParticipant]) {
        let newVideoStates = createVideoStateMap(using: newParticipants)
        Log.haptics.debug("updating video state map: \(newVideoStates), old: \(videoStates)")

        let mappedNewVideoStates = newVideoStates.mapKeys({$0.hashValue})
        for (participant, wasSending) in videoStates {

            if let isSending = mappedNewVideoStates[participant.hashValue], isSending != wasSending {
                Log.haptics.debug("triggering toggle video event")
                hapticGenerator.trigger(event: .toggleVideo)
            }
        }

        videoStates = newVideoStates
    }

    private func createVideoStateMap(using participants: [CallParticipant]) -> [CallParticipant: Bool] {
        return Dictionary(participants.map { ($0, $0.state.isSendingVideo) }, uniquingKeysWith: { (first, _) in first })
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
