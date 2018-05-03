//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "UI")

class RecentlyUsedEmojiSection: NSObject, EmojiSection {

    let type: EmojiSectionType = .recent

    private(set) var emoji = [Emoji]()
    private let backing: NSMutableOrderedSet
    private let capacity: Int

    init(capacity: Int, elements: [Emoji] = []) {
        self.capacity = capacity
        self.backing = NSMutableOrderedSet(array: elements)
        super.init()
        updateContent()
    }

    @discardableResult func register(_ element: Emoji) -> Bool {
        switch backing.index(of: element) {
        case 0: return false // No update neccessary if the first element is already the new one
        case NSNotFound: backing.insert(element, at: 0)
        case let idx: backing.moveObjects(at: IndexSet(integer: idx), to: 0)
        }

        updateContent()
        return true
    }

    private func updateContent() {
        defer { emoji = backing.array as! [Emoji] }
        guard backing.count > capacity else { return }
        backing.removeObjects(at: IndexSet(integersIn: capacity..<backing.count))
    }
    
}


class RecentlyUsedEmojiPeristenceCoordinator {

    static func loadOrCreate() -> RecentlyUsedEmojiSection {
        return loadFromDisk() ?? RecentlyUsedEmojiSection(capacity: 15)
    }

    static func store(_ section: RecentlyUsedEmojiSection) {
        guard let emojiUrl = url else { return }
        createDirectoryIfNeeded()
        (section.emoji as NSArray).write(to: emojiUrl, atomically: true)
    }

    private static func loadFromDisk() -> RecentlyUsedEmojiSection? {
        guard let emojiUrl = url else { return nil }
        guard let emoji = NSArray(contentsOf: emojiUrl) as? [Emoji] else { return nil }
        return RecentlyUsedEmojiSection(capacity: 15, elements: emoji)
    }

    private static func createDirectoryIfNeeded() {
        guard let url = directoryURL else { return }
        
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }

            try url.wr_excludeFromBackup()
        }
        catch (let exception) {
            zmLog.error("Error creating \(String(describing: directoryURL)): \(exception)")
        }
    }

    private static var directoryURL: URL? = {
        let url = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url?.appendingPathComponent("emoji")
    }()

    private static var url: URL? = {
        return directoryURL?.appendingPathComponent("recently_used.plist")
    }()

}
