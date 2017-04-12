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


/// Class describing unsent message drafts for later sending or further editing.
final class MessageDraft: NSObject, NSCoding {

    /// The subject of the message
    var subject: String?
    /// The message content
    var message: String?
    /// A date indicating when the draft was last modified
    var lastModified = Date()

    init(subject: String?, message: String?, lastModified: Date? = nil) {
        self.subject = subject
        self.message = message
        if let lastModified = lastModified {
            self.lastModified = lastModified
        }
        super.init()
    }

    // MARK: NSCoding

    convenience init?(coder aDecoder: NSCoder) {
        self.init(
            subject: aDecoder.decodeObject(forKey: #keyPath(MessageDraft.subject)) as? String,
            message: aDecoder.decodeObject(forKey: #keyPath(MessageDraft.message)) as? String,
            lastModified: aDecoder.decodeObject(forKey: #keyPath(MessageDraft.lastModified)) as? Date
        )
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(subject, forKey: #keyPath(MessageDraft.subject))
        aCoder.encode(message, forKey: #keyPath(MessageDraft.message))
        aCoder.encode(lastModified, forKey: #keyPath(MessageDraft.lastModified))
    }

}


func ==(lhs: MessageDraft, rhs: MessageDraft) -> Bool {
    return lhs.subject == rhs.subject && lhs.message == rhs.message && lhs.lastModified == rhs.lastModified
}


/// Class used to store objects of type `MessageDraft` on disk.
/// Creates a directory to store the serialized objects if not yet present.
final class MessageDraftStorage: NSObject {

    private let directoryURL: URL
    private let draftsURL: URL
    private let filemanager = FileManager.default

    init(sharedContainerURL: URL) throws {
        directoryURL = sharedContainerURL.appendingPathComponent("MessageDraftStorage")
        draftsURL =  directoryURL.appendingPathComponent("Drafts")
        super.init()
        try createDirectoryIfNeeded(at: directoryURL)
    }

    private func createDirectoryIfNeeded(at url: URL) throws {
        if !filemanager.fileExists(atPath: url.path) {
            try filemanager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        try url.wr_excludeFromBackup()
    }

    func store(_ drafts: [MessageDraft]) throws {
        let data = NSKeyedArchiver.archivedData(withRootObject: drafts)
        try data.write(to: draftsURL, options: .atomic)
    }

    func storedDrafts() throws -> [MessageDraft] {
        let data = try Data(contentsOf: draftsURL)
        guard let drafts = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MessageDraft] else { return [] }
        return drafts.sorted { (lhs, rhs) in lhs.lastModified > rhs.lastModified }
    }

}
