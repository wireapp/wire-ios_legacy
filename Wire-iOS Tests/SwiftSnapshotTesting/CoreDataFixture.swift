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

import WireTesting
import XCTest
@testable import Wire


/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
final class CoreDataFixture {

    var selfUserInTeam: Bool = false
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    var team: Team?
    var teamMember: Member?
    let usernames = ["Anna", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus", "Lena", "Linea", "Lara", "Elliot", "Francois", "Felix", "Brian", "Brett", "Hannah", "Ana", "Paula"]


    ///From ZMSnapshot

    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    var uiMOC: NSManagedObjectContext!

    /// The color of the container view in which the view to
    /// be snapshot will be placed, defaults to UIColor.lightGrayColor
    var snapshotBackgroundColor: UIColor?

    /// If YES the uiMOC will have image and file caches. Defaults to NO.
    var needsCaches: Bool {
        get {
            return false
        }
    }

    /// If this is set the accent color will be overriden for the tests
    var accentColor: ZMAccentColor {
        set {
            UIColor.setAccentOverride(newValue)
        }
        get {
            return UIColor.accentOverrideColor()
        }
    }

    var documentsDirectory: URL?

    init() {
        ///From ZMSnapshotTestCase

        XCTAssertEqual(UIScreen.main.scale, 2, "Snapshot tests need to be run on a device with a 2x scale")
        if UIDevice.current.systemVersion.compare("10", options: .numeric, range: nil, locale: .current) == .orderedAscending {
            XCTFail("Snapshot tests need to be run on a device running at least iOS 10")
        }
        AppRootViewController.configureAppearance()
        UIView.setAnimationsEnabled(false)
        accentColor = .vividRed
        snapshotBackgroundColor = UIColor.clear

        let group = DispatchGroup()

        group.enter()

        StorageStack.reset()
        StorageStack.shared.createStorageAsInMemory = true
        do {
            documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            XCTAssertNil(error, "Unexpected error \(error)")
        }

        StorageStack.shared.createManagedObjectContextDirectory(accountIdentifier: UUID(), applicationContainer: documentsDirectory!, dispatchGroup: nil, startedMigrationCallback: nil, completionHandler: { contextDirectory in
            self.uiMOC = contextDirectory.uiContext
            group.leave()
        })

        group.wait()

        if needsCaches {
            setUpCaches()
        }

        /////////////////////////

        snapshotBackgroundColor = .white
        setupTestObjects()

        MockUser.setMockSelf(selfUser)

    }

    deinit {
        selfUser = nil
        otherUser = nil
        otherUserConversation = nil
        teamMember = nil
        team = nil

        MockUser.setMockSelf(nil)
    }

    func setUpCaches() {
        uiMOC.zm_userImageCache = UserImageLocalCache(location: nil)
        uiMOC.zm_fileAssetCache = FileAssetCache(location: nil)
    }

    // MARK: – Setup

    private func setupMember() {
        let selfUser = ZMUser.selfUser(in: self.uiMOC)

        team = Team.insertNewObject(in: uiMOC)
        team!.remoteIdentifier = UUID()
        

        teamMember = Member.insertNewObject(in: uiMOC)
        teamMember!.user = selfUser
        teamMember!.team = team
        teamMember!.setTeamRole(.member)
    }

    private func setupTestObjects() {
        selfUser = ZMUser.insertNewObject(in: uiMOC)
        selfUser.remoteIdentifier = UUID()
        selfUser.name = "selfUser"
        selfUser.accentColorValue = .vividRed
        selfUser.emailAddress = "test@email.com"
        selfUser.phoneNumber = "+123456789"

        ZMUser.boxSelfUser(selfUser, inContextUserInfo: uiMOC)
        if selfUserInTeam {
            setupMember()
        }

        otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"
        otherUser.setHandle("bruno")
        otherUser.accentColorValue = .brightOrange

        otherUserConversation = ZMConversation.insertNewObject(in: uiMOC)
        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.remoteIdentifier = UUID.create()
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = otherUser
        connection.status = .accepted
        connection.conversation = otherUserConversation

        uiMOC.saveOrRollback()
    }

    private func updateTeamStatus(wasInTeam: Bool) {
        guard wasInTeam != selfUserInTeam else {
            return
        }

        if selfUserInTeam {
            setupMember()
        } else {
            teamMember = nil
            team = nil
        }
    }

    func createGroupConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = .group
        conversation.internalAddParticipants([selfUser, otherUser])
        return conversation
    }
    
    func createTeamGroupConversation() -> ZMConversation {
        let conversation = createGroupConversation()
        conversation.teamRemoteIdentifier = UUID.create()
        conversation.userDefinedName = "Group conversation"
        return conversation
    }
    
    func createUser(name: String) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID()
        return user
    }
    
    func createService(name: String) -> ZMUser {
        let user = createUser(name: name)
        user.serviceIdentifier = UUID.create().transportString()
        user.providerIdentifier = UUID.create().transportString()
        return user
    }

    func nonTeamTest(_ block: () -> Void) {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = false
        updateTeamStatus(wasInTeam: wasInTeam)
        block()
    }

    func teamTest(_ block: () -> Void) {
        let wasInTeam = selfUserInTeam
        selfUserInTeam = true
        updateTeamStatus(wasInTeam: wasInTeam)
        block()
    }
    
    func markAllMessagesAsUnread(in conversation: ZMConversation) {
        conversation.lastReadServerTimeStamp = Date.distantPast
        conversation.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadCountKey)
    }

}

//MARK: - mock service user

extension CoreDataFixture {
    func createServiceUser() -> ZMUser {
        let serviceUser = ZMUser.insertNewObject(in: uiMOC)
        serviceUser.remoteIdentifier = UUID()
        serviceUser.name = "ServiceUser"
        serviceUser.setHandle(serviceUser.name!.lowercased())
        serviceUser.accentColorValue = .brightOrange
        serviceUser.serviceIdentifier = UUID.create().transportString()
        serviceUser.providerIdentifier = UUID.create().transportString()
        uiMOC.saveOrRollback()

        return serviceUser
    }
}

