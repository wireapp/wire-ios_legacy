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

import Foundation

extension PersistedDataPatch {

    /// List of patches to apply
    static let allPatchesToApply = [
        PersistedDataPatch(version: "41.0.0", block: UserClient.migrateAllSessionsClientIdentifiersV2),
        PersistedDataPatch(version: "43.0.4", block: ZMConversation.migrateAllSecureWithIgnored),
        PersistedDataPatch(version: "58.4.1", block: Team.deleteLocalTeamsAndMembers),
        PersistedDataPatch(version: "62.1.0", block: Member.migrateRemoteIdentifiers),
        PersistedDataPatch(version: "78.1.0", block: DuplicatedEntityRemoval.removeDuplicated),
        PersistedDataPatch(version: "81.2.1", block: InvalidClientsRemoval.removeInvalid),
        PersistedDataPatch(version: "103.0.2", block: InvalidGenericMessageDataRemoval.removeInvalid),
        PersistedDataPatch(version: "145.0.3", block: InvalidConversationRemoval.removeInvalid),
        PersistedDataPatch(version: "161.0.1", block: TransferStateMigration.migrateLegacyTransferState),
        PersistedDataPatch(version: "167.3.0", block: AvailabilityBehaviourChange.notifyAvailabilityBehaviourChange),
        PersistedDataPatch(version: "198.0.0", block: ZMConversation.introduceParticipantRoles),
        PersistedDataPatch(version: "220.0.4", block: InvalidConnectionRemoval.removeInvalid),
        PersistedDataPatch(version: "234.0.0", block: TransferApplockKeychain.migrateKeychainItems),
        PersistedDataPatch(version: "234.1.1", block: InvalidConnectionRemoval.removeInvalid),
        PersistedDataPatch(version: "236.0.0", block: MigrateSenderClient.migrateSenderClientID),
        PersistedDataPatch(version: "243.0.0", block: InvalidFeatureRemoval.removeInvalid),
        PersistedDataPatch(version: "273.2.0", block: InvalidDomainRemoval.removeDuplicatedEntitiesWithInvalidDomain),
        PersistedDataPatch(version: "279.0.4", block: InvalidFeatureRemoval.restoreDefaultConferenceCallingConfig),
        PersistedDataPatch(version: "285.0.0", block: ZMConversation.introduceAccessRoleV2)
    ]

}
