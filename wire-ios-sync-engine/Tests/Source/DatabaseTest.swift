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

class DatabaseTest: ZMTBaseTest {

    let accountId = UUID()
    var coreDataStack: CoreDataStack?

    var useInMemoryDatabase: Bool {
        return true
    }

    var uiMOC: NSManagedObjectContext {
        return self.coreDataStack!.viewContext
    }

    var syncMOC: NSManagedObjectContext {
        return self.coreDataStack!.syncContext
    }

    var searchMOC: NSManagedObjectContext {
        return self.coreDataStack!.searchContext
    }

    var sharedContainerURL: URL? {
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let groupIdentifier = "group." + bundleIdentifier!
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
    }

    private func cleanUp() {
        try? FileManager.default.contentsOfDirectory(at: sharedContainerURL!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }

    private func createCoreDataStack() -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: accountId)
        let stack = CoreDataStack(account: account,
                                  applicationContainer: sharedContainerURL!,
                                  inMemoryStore: true,
                                  dispatchGroup: dispatchGroup)

        stack.loadStores { (error) in
            XCTAssertNil(error)
        }

        return stack
    }

    private func configureCaches() {
        let fileAssetCache = FileAssetCache(location: nil)
        let userImageCache = UserImageLocalCache(location: nil)

        uiMOC.zm_fileAssetCache = fileAssetCache
        uiMOC.zm_userImageCache = userImageCache

        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_fileAssetCache = fileAssetCache
            self.uiMOC.zm_userImageCache = userImageCache
        }
    }

    override func setUp() {
        super.setUp()

        self.coreDataStack = createCoreDataStack()

        configureCaches()
    }

    override func tearDown() {
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        coreDataStack = nil

        cleanUp()

        super.tearDown()
    }

    // MARK: - Helper methods

    func performPretendingUIMocIsSyncMoc(_ block: () -> Void) {
        uiMOC.resetContextType()
        uiMOC.markAsSyncContext()
        block()
        uiMOC.resetContextType()
        uiMOC.markAsUIContext()
    }

    func event(withPayload payload: [AnyHashable: Any]?, type: ZMUpdateEventType, in conversation: ZMConversation, user: ZMUser) -> ZMUpdateEvent {
        return ZMUpdateEvent(uuid: nil, payload: eventPayload(content: payload, type: type, in: conversation, from: user), transient: false, decrypted: true, source: .download)!
    }

    private func eventPayload(content: [AnyHashable: Any]?,
                              type: ZMUpdateEventType,
                              in conversation: ZMConversation,
                              from user: ZMUser,
                              timestamp: Date = Date()) -> [AnyHashable: Any] {
        return [ "conversation": conversation.remoteIdentifier!.transportString(),
                 "data": conversation,
                 "from": user.remoteIdentifier!.transportString(),
                 "time": timestamp.transportString(),
                 "type": ZMUpdateEvent.eventTypeString(for: type)!
        ]
    }

}
