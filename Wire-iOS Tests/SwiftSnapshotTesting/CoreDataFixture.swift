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

// MARK: - factory methods

extension ZMConversation {
    static func createOtherUserConversation(moc: NSManagedObjectContext, otherUser: ZMUser) -> ZMConversation {

        let otherUserConversation = ZMConversation.insertNewObject(in: moc)
        otherUserConversation.add(participants: ZMUser.selfUser(in: moc))

        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.remoteIdentifier = UUID.create()
        let connection = ZMConnection.insertNewObject(in: moc)
        connection.to = otherUser
        connection.status = .accepted
        connection.conversation = otherUserConversation

        connection.add(user: otherUser)

        return otherUserConversation
    }

    static func createGroupConversationOnlyAdmin(moc: NSManagedObjectContext, selfUser: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = .group

        let role = Role(context: moc)
        role.name = ZMConversation.defaultAdminRoleName
        conversation.addParticipantsAndUpdateConversationState(users: [selfUser], role: role)

        return conversation
    }

    static func createGroupConversation(moc: NSManagedObjectContext,
                                        otherUser: ZMUser,
                                        selfUser: ZMUser) -> ZMConversation {
        let conversation = createGroupConversationOnlyAdmin(moc: moc, selfUser: selfUser)
        conversation.add(participants: otherUser)
        return conversation
    }

    static func createTeamGroupConversation(moc: NSManagedObjectContext,
                                            otherUser: ZMUser,
                                            selfUser: ZMUser) -> ZMConversation {
        let conversation = createGroupConversation(moc: moc, otherUser: otherUser, selfUser: selfUser)
        conversation.teamRemoteIdentifier = UUID.create()
        conversation.userDefinedName = "Group conversation"
        return conversation
    }

}

/// This class provides a `NSManagedObjectContext` in order to test views with real data instead
/// of mock objects.
final class CoreDataFixture {

    private var selfUserInTeam: Bool = false
    var selfUser: ZMUser!
    var otherUser: ZMUser!
    var otherUserConversation: ZMConversation!
    var team: Team?
    var teamMember: Member?
    let usernames = ["Anna", "Claire", "Dean", "Erik", "Frank", "Gregor", "Hanna", "Inge", "James", "Laura", "Klaus", "Lena", "Linea", "Lara", "Elliot", "Francois", "Felix", "Brian", "Brett", "Hannah", "Ana", "Paula"]

    // The provider to use when configuring `SelfUser.provider`, needed only when tested code
    // invokes `SelfUser.current`. As we slowly migrate to `UserType`, we will use this more
    // and the `var selfUser: ZMUser!` less.
    //
    var selfUserProvider: SelfUserProvider!

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
            return UIColor.accentOverrideColor!
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
        selfUserProvider = SelfProvider(selfUser: selfUser)

        SelfUser.provider = selfUserProvider
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

        otherUserConversation = ZMConversation.createOtherUserConversation(moc: uiMOC, otherUser: otherUser)

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

// MARK: - mock service user

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

protocol CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture! { get }

    /// with default implementation
    var otherUser: ZMUser! { get }
    var selfUser: ZMUser! { get }

    var otherUserConversation: ZMConversation! { get }

    func createGroupConversation() -> ZMConversation
    func createTeamGroupConversation() -> ZMConversation

    func createUser(name: String) -> ZMUser

    func teamTest(_ block: () -> Void)

    func mockUserClient() -> UserClient!

  func createGroupConversationOnlyAdmin() -> ZMConversation
}

// MARK: - default implementation for migrating CoreDataSnapshotTestCase to XCTestCase
extension CoreDataFixtureTestHelper {
    var otherUser: ZMUser! {
        return coreDataFixture.otherUser
    }

    var selfUser: ZMUser! {
        return coreDataFixture.selfUser
    }

    var otherUserConversation: ZMConversation! {
        return coreDataFixture.otherUserConversation
    }

    func createGroupConversation() -> ZMConversation {
        return ZMConversation.createGroupConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    func createTeamGroupConversation() -> ZMConversation {
        return ZMConversation.createTeamGroupConversation(moc: coreDataFixture.uiMOC, otherUser: otherUser, selfUser: selfUser)
    }

    func createUser(name: String) -> ZMUser {
        return coreDataFixture.createUser(name: name)
    }

    func teamTest(_ block: () -> Void) {
        coreDataFixture.teamTest(block)
    }

    func nonTeamTest(_ block: () -> Void) {
        coreDataFixture.nonTeamTest(block)
    }

    var uiMOC: NSManagedObjectContext! {
        return coreDataFixture.uiMOC
    }

    var usernames: [String] {
        return coreDataFixture.usernames
    }

    var team: Team? {
        return coreDataFixture.team
    }

    func mockUserClient() -> UserClient! {
        return coreDataFixture.mockUserClient()
    }

  func createGroupConversationOnlyAdmin() -> ZMConversation {
        return ZMConversation.createGroupConversationOnlyAdmin(moc: uiMOC, selfUser: selfUser)
    }
}
