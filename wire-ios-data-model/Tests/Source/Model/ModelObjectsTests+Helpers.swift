//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ModelObjectsTests {

    // MARK: Users & Teams Members

    @discardableResult func createTeamAndMember(for user: ZMUser, with permissions: Permissions? = nil) -> (Team, Member) {
        let member = Member.insertNewObject(in: uiMOC)
        member.team = .insertNewObject(in: uiMOC)
        member.team?.remoteIdentifier = .create()
        member.user = user
        if let permissions = permissions {
            member.permissions = permissions
        }
        return (member.team!, member)
    }

    @discardableResult func createUserAndAddMember(to team: Team, with domain: String? = nil) -> (ZMUser, Member) {
        let member = Member.insertNewObject(in: uiMOC)
        member.user = .insertNewObject(in: uiMOC)
        member.user?.remoteIdentifier = .create()
        member.user?.teamIdentifier = team.remoteIdentifier
        member.user?.domain = domain
        member.team = team
        return (member.user!, member)
    }

    @objc(userWithClients:trusted:)
    public func userWithClients(count: Int, trusted: Bool) -> ZMUser {
        self.createSelfClient()
        self.uiMOC.refreshAllObjects()

        let selfClient: UserClient? = ZMUser.selfUser(in: self.uiMOC).selfClient()
        let user: ZMUser = ZMUser.insertNewObject(in: self.uiMOC)
        [0...count].forEach({ _ in
            let client: UserClient = UserClient.insertNewObject(in: self.uiMOC)
            client.user = user
            if trusted {
                selfClient?.trustClient(client)
            } else {
                selfClient?.ignoreClient(client)
            }
        })
        return user
    }

    // MARK: Files

    func createFileMetadata(filename: String? = nil) -> ZMFileMetadata {
        let fileURL: URL

        if let fileName = filename {
            fileURL = testURLWithFilename(fileName)
        } else {
            fileURL = testURLWithFilename("file.dat")
        }

        _ = createTestFile(at: fileURL)

        return ZMFileMetadata(fileURL: fileURL)
    }

    func testURLWithFilename(_ filename: String) -> URL {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documents)
        return documentsURL.appendingPathComponent(filename)
    }

    func createTestFile(at url: URL) -> Data {
        let data: Data! = "Some other data".data(using: String.Encoding.utf8)
        try! data.write(to: url, options: [])
        return data
    }

    func removeTestFile(at url: URL) {
        do {
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path) {
                return
            }
            try fm.removeItem(at: url)
        } catch {
            XCTFail("Error removing file: \(error)")
        }
    }

}
