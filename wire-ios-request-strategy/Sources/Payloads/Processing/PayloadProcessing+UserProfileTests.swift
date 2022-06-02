// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import XCTest
@testable import WireRequestStrategy

class PayloadProcessing_UserProfileTests: MessagingTestBase {

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            self.otherUser.remoteIdentifier = nil
            self.otherUser.domain = nil
        }
    }

    override func tearDown() {
        APIVersion.isFederationEnabled = false
        super.tearDown()
    }

    func testUpdateUserProfile_UpdatesID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let userProfile = Payload.UserProfile(id: UUID())

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, userProfile.id)
        }
    }

    func testUpdateUserProfile_UpdatesQualifiedUserID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            APIVersion.isFederationEnabled = true
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, qualifiedID.uuid)
            XCTAssertEqual(self.otherUser.domain, qualifiedID.domain)
        }
    }

    func testUpdateUserProfile_DoesntUpdatesQualifiedUserID_WhenFederationIsDisabled() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            APIVersion.isFederationEnabled = false
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(id: qualifiedID.uuid, qualifiedID: qualifiedID)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.remoteIdentifier, qualifiedID.uuid)
            XCTAssertNil(self.otherUser.domain)
        }
    }

    func testUpdateUserProfile_UpdatesTeamID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, teamID: UUID())

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.teamIdentifier, userProfile.teamID)
        }
    }

    func testUpdateUserProfile_TeamIDCanBeDeleted_ByNonAuthoritativeUpdate() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, updatedKeys: [.teamID])

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: false)

            // then
            XCTAssertNil(self.otherUser.teamIdentifier)
        }
    }

    func testUpdateUserProfile_TeamMembershipIsCreated_WhenUserBelongsToSelfUserTeam() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let teamID = UUID()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamID
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, teamID: teamID)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.membership?.team, team)
        }
    }

    func testUpdateUserProfile_UpdatesServiceID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let serviceID = Payload.ServiceID(id: UUID(), provider: UUID())
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, serviceID: serviceID)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.serviceIdentifier, serviceID.id.transportString())
            XCTAssertEqual(self.otherUser.providerIdentifier, serviceID.provider.transportString())
        }
    }

    func testUpdateUserProfile_UpdatesSSOID() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let SSOID = Payload.SSOID(tenant: "a", subject: "b", scimExternalID: "c")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, SSOID: SSOID)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertTrue(self.otherUser.usesCompanyLogin)
        }
    }

    func testUpdateUserProfile_UpdatesName() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let name = "John Doe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: name)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.name, name)
        }
    }

    func testUpdateUserProfile_NameIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let oldName = "John Doe"
            let newName = "Nhoj Eod"
            self.otherUser.name = oldName
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: newName)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.name, oldName)
        }
    }

    func testUpdateUserProfile_UpdatesHandle() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let handle = "johndoe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, handle: handle)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.handle, handle)
        }
    }

    func testUpdateUserProfile_HandleIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let oldHandle = "johndoe"
            let newhandle = "eodnhoj"
            self.otherUser.handle = oldHandle
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, handle: newhandle)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.handle, oldHandle)
        }
    }

    func testUpdateUserProfile_UpdatesPhone() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let phone = "+123456789"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, phone: phone)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.phoneNumber, phone)
        }
    }

    func testUpdateUserProfile_PhoneCanBeDeleted_ByNonAuthoritativeUpdate() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let updatedKeysSet: Set<Payload.UserProfile.CodingKeys> = [.phone]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, updatedKeys: updatedKeysSet)
            self.otherUser.phoneNumber = "+123456789"

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: false)

            // then
            XCTAssertNil(self.otherUser.phoneNumber)
        }
    }

    func testUpdateUserProfile_PhoneIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let oldPhone = "+123456789"
            let newPhone = "+987654321"
            self.otherUser.phoneNumber = oldPhone
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, phone: newPhone)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.phoneNumber, oldPhone)
        }
    }

    func testUpdateUserProfile_UpdatesEmail() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let email = "john.doe@example.com"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, email: email)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.emailAddress, email)
        }
    }

    func testUpdateUserProfile_EmailCanBeDeleted_ByNonAuthoritativeUpdate() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let updatedKeysSet: Set<Payload.UserProfile.CodingKeys> = [.email]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, updatedKeys: updatedKeysSet)
            self.otherUser.emailAddress = "john.doe@example.com"

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: false)

            // then
            XCTAssertNil(self.otherUser.emailAddress)
        }
    }

    func testUpdateUserProfile_EmailIsNotUpdated_WhenUserIsDeleted() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let oldEmail = "john.doe@example.com"
            let newEmail = "john.eod@example.com"
            self.otherUser.emailAddress = oldEmail
            self.otherUser.markAccountAsDeleted(at: Date())
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, email: newEmail)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.emailAddress, oldEmail)
        }
    }

    func testUpdateUserProfile_UpdatesAssets() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let previewAsset = Payload.Asset(key: "1", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.previewProfileAssetIdentifier, previewAsset.key)
            XCTAssertEqual(self.otherUser.completeProfileAssetIdentifier, completeAsset.key)
        }
    }

    func testUpdateUserProfile_AssetsIsNotUpdated_WhenAssetsHaveLocalChanges() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let assetsModifiedKeys = [ZMUser.previewProfileAssetIdentifierKey,
                                      ZMUser.completeProfileAssetIdentifierKey]
            let oldPreviewAssetKey = "a"
            let oldCompleteAssetKey = "b"
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.previewProfileAssetIdentifier = oldPreviewAssetKey
            selfUser.completeProfileAssetIdentifier = oldCompleteAssetKey
            selfUser.setLocallyModifiedKeys(Set(assetsModifiedKeys))
            let qualifiedID = QualifiedID(uuid: selfUser.remoteIdentifier, domain: "example.com")
            let previewAsset = Payload.Asset(key: "1", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            userProfile.updateUserProfile(for: selfUser, authoritative: true)

            // then
            XCTAssertEqual(selfUser.previewProfileAssetIdentifier, oldPreviewAssetKey)
            XCTAssertEqual(selfUser.completeProfileAssetIdentifier, oldCompleteAssetKey)
        }
    }

    func testUpdateUserProfile_AssetsAreRejected_WhenAssetsKeysAreInvalid() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            self.otherUser.previewProfileAssetIdentifier = "a"
            self.otherUser.completeProfileAssetIdentifier = "b"
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let previewAsset = Payload.Asset(key: "1<", size: .preview, type: .image)
            let completeAsset = Payload.Asset(key: "2\"", size: .complete, type: .image)
            let assets = [previewAsset, completeAsset]
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, assets: assets)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertNil(self.otherUser.previewProfileAssetIdentifier)
            XCTAssertNil(self.otherUser.completeProfileAssetIdentifier)
        }
    }

    func testUpdateUserProfile_UpdatesManagedBy() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let managedBy = "wire"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, managedBy: managedBy)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertTrue(self.otherUser.managedByWire)
        }
    }

    func testUpdateUserProfile_UpdatesAccentColor() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let accentColor = ZMAccentColor(rawValue: 3)
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, accentColor: Int(accentColor!.rawValue))

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.accentColorValue, accentColor)
        }
    }

    func testUpdateUserProfile_UpdatesIsDeleted() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, isDeleted: true)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertTrue(self.otherUser.isAccountDeleted)
        }
    }

    func testUpdateUserProfile_UpdatesExpiresAt() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let expiresAt = Date()
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, expiresAt: expiresAt)

            // when
            userProfile.updateUserProfile(for: self.otherUser, authoritative: true)

            // then
            XCTAssertEqual(self.otherUser.expiresAt, expiresAt)
        }
    }

    func testUpdateUserProfiles_AppliesUpdateOnUserProfileList() throws {
        syncMOC.performGroupedBlockAndWait {
            // given
            let qualifiedID = QualifiedID(uuid: UUID(), domain: "example.com")
            let name = "John Doe"
            let userProfile = Payload.UserProfile(qualifiedID: qualifiedID, name: name)
            self.otherUser.remoteIdentifier = qualifiedID.uuid
            self.otherUser.domain = qualifiedID.domain
            self.syncMOC.saveOrRollback()

            // when
            [userProfile].updateUserProfiles(in: self.syncMOC)

            // then
            XCTAssertEqual(self.otherUser.name, name)
        }
    }

}
