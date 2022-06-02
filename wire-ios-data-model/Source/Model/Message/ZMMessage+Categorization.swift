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

extension ZMMessage {

    /// Type of content present in the message
    public var category: MessageCategory {

        let category = self.categoryFromContent
        guard category != .none else {
            return .undefined
        }

        return category.union(self.likedCategory)
    }

    /// Obj-c compatible function
    @objc public func updateCategoryCache() {
        _ = self.storeCategoryCache()
    }

    /// A cached version of the cateogry. The getter will recalculate the category if not set already
    public var cachedCategory: MessageCategory {

        get {
            self.willAccessValue(forKey: ZMMessageCachedCategoryKey)
            let value = (self.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber) ?? NSNumber(value: 0)
            self.didAccessValue(forKey: ZMMessageCachedCategoryKey)

            var category = MessageCategory(rawValue: value.int32Value)
            if category == .none {
                category = self.storeCategoryCache()
            }
            return category
        }

        set {
            self.willChangeValue(forKey: ZMMessageCachedCategoryKey)
            self.setPrimitiveValue(NSNumber(value: newValue.rawValue), forKey: ZMMessageCachedCategoryKey)
            self.didChangeValue(forKey: ZMMessageCachedCategoryKey)
        }
    }

    /// Calculate and save category in the category cache field. If no category
    /// is passed, it will compute it before storing it.
    /// - returns: the category that was stored
    public func storeCategoryCache(category: MessageCategory? = nil) -> MessageCategory {
        let categoryToStore = category ?? self.category
        self.cachedCategory = categoryToStore
        return categoryToStore
    }

    /// Sorted fetch request by category. It will match a Core Data object if the intersection of the Core Data value and ANY of the passed
    /// in categories is matching that category (in other words, the Core Data value can have more bits set that a certain category and it will
    /// still match).
    public static func fetchRequestMatching(categories: Set<MessageCategory>,
                                            excluding: MessageCategory = .none,
                                            conversation: ZMConversation? = nil) -> NSFetchRequest<NSFetchRequestResult> {

        let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: categories.map {
            return NSPredicate(format: "(%K & %d) = %d", ZMMessageCachedCategoryKey, $0.rawValue, $0.rawValue)
        })

        let excludingPredicate: NSPredicate? = (excluding != .none)
        ? NSPredicate(format: "(%K & %d) = 0", ZMMessageCachedCategoryKey, excluding.rawValue)
        : nil
        let conversationPredicate: NSPredicate? = (conversation != nil)
        ? NSPredicate(format: "%K = %@", ZMMessageConversationKey, conversation!)
        : nil

        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [orPredicate, excludingPredicate, conversationPredicate].compactMap { $0 })
        return self.sortedFetchRequest(with: finalPredicate)
    }

    public static func fetchRequestMatching(matchPairs: [CategoryMatch],
                                            conversation: ZMConversation? = nil) -> NSFetchRequest<NSFetchRequestResult> {

        let categoryPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: matchPairs.map {
            if $0.excluding != .none {
                return NSPredicate(format: "((%K & %d) = %d) && ((%K & %d) = 0)" ,
                                   ZMMessageCachedCategoryKey, $0.including.rawValue, $0.including.rawValue,
                                   ZMMessageCachedCategoryKey, $0.excluding.rawValue)
            }
            return NSPredicate(format: "(%K & %d) = %d", ZMMessageCachedCategoryKey, $0.including.rawValue, $0.including.rawValue)
        })
        let conversationPredicate: NSPredicate? = (conversation != nil)
        ? NSPredicate(format: "%K = %@", ZMMessageConversationKey, conversation!)
        : nil

        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, conversationPredicate].compactMap { $0 })
        return self.sortedFetchRequest(with: finalPredicate)
    }

}

// MARK: - Categories from specific content
let linkParser = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

extension ZMMessage {

    /// Category according only to content (excluding likes)
    fileprivate var categoryFromContent: MessageCategory {

        guard !self.isObfuscated, !self.isZombieObject else {
            return .none
        }

        let category = [self.textCategory,
                        self.imageCategory,
                        self.fileCategory,
                        self.locationCategory,
                        self.knockCategory,
                        self.systemMessageCategory
        ]
            .reduce(MessageCategory.none) {
                (current: MessageCategory, other: MessageCategory) in
                return current.union(other)
            }
        return category
    }

    fileprivate var imageCategory: MessageCategory {
        guard let imageMessageData = self.imageMessageData else {
            return .none
        }
        var category = MessageCategory.image
        if let asset = self as? ZMAssetClientMessage, (asset.mediumGenericMessage == nil && imageMessageData.imageData == nil) {
            category.update(with: .excludedFromCollection)
        }
        if imageMessageData.isAnimatedGIF {
            category.update(with: .GIF)
        }
        return category
    }

    fileprivate var textCategory: MessageCategory {
        guard let textData = self.textMessageData,
              let text = textData.messageText, !text.isEmpty else {
                  return .none
              }
        var category = MessageCategory.text
        if textData.linkPreview != nil {
            category.update(with: .link)
            category.update(with: .linkPreview)
        }
        else {
            // does the text itself includes a link?
            let matches = linkParser.matches(in: text, range: NSRange(location: 0, length: text.count))
            if matches.count > 0 {
                category.update(with: .link)
            }
        }
        return category
    }

    fileprivate var fileCategory: MessageCategory {
        guard let fileData = self.fileMessageData,
              self.imageCategory == .none else {
                  return .none
              }
        var category = MessageCategory.file
        if let asset = self as? ZMAssetClientMessage, asset.transferState.isOne(of: [.uploadingFailed, .uploadingCancelled]) {
            category.update(with: .excludedFromCollection)
        }
        if fileData.isAudio {
            category.update(with: .audio)
        }
        else if fileData.isVideo {
            category.update(with: .video)
        }
        return category
    }

    fileprivate var locationCategory: MessageCategory {
        if self.locationMessageData != nil {
            return .location
        }
        return .none
    }

    fileprivate var likedCategory: MessageCategory {
        guard !self.reactions.isEmpty else {
            return .none
        }
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        for reaction in self.reactions {
            if reaction.users.contains(selfUser) {
                return .liked
            }
        }
        return .none
    }

    fileprivate var knockCategory: MessageCategory {
        guard self.knockMessageData != nil else {
            return .none
        }
        return .knock
    }

    fileprivate var systemMessageCategory: MessageCategory {
        guard self.systemMessageData != nil else {
            return .none
        }
        return .systemMessage
    }
}

// MARK: - Categories
/// Type of content in a message
public struct MessageCategory: OptionSet {

    public let rawValue: Int32

    public static let none = MessageCategory([])
    public static let undefined = MessageCategory(rawValue: 1 << 0)
    public static let text = MessageCategory(rawValue: 1 << 1)
    public static let link = MessageCategory(rawValue: 1 << 2)
    public static let image = MessageCategory(rawValue: 1 << 3)
    public static let GIF = MessageCategory(rawValue: 1 << 4)
    public static let file = MessageCategory(rawValue: 1 << 5)
    public static let audio = MessageCategory(rawValue: 1 << 6)
    public static let video = MessageCategory(rawValue: 1 << 7)
    public static let location = MessageCategory(rawValue: 1 << 8)
    public static let liked = MessageCategory(rawValue: 1 << 9)
    public static let knock = MessageCategory(rawValue: 1 << 10)
    public static let systemMessage = MessageCategory(rawValue: 1 << 11)
    public static let excludedFromCollection = MessageCategory(rawValue: 1 << 12)
    public static let linkPreview = MessageCategory(rawValue: 1 << 13)

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

extension MessageCategory: CustomDebugStringConvertible {

    fileprivate static let descriptions: [MessageCategory: String] = [
        .undefined: "Undefined",
        .text: "Text",
        .link: "Link",
        .image: "Image",
        .GIF: "GIF",
        .file: "File",
        .audio: "Audio",
        .video: "Video",
        .location: "Location",
        .liked: "Liked",
        .knock: "Knock",
        .systemMessage: "System message",
        .excludedFromCollection: "Excluded from collection",
        .linkPreview: "Link preview"
    ]

    public var debugDescription: String {
        let categories = MessageCategory.descriptions
            .filter { (category, _) -> Bool in
                return contains(category)
            }.map { (_, description) -> String in
                return description
            }
        let description = categories.isEmpty ? "None" : categories.joined(separator: ", ")
        return description
    }
}

extension MessageCategory: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }

}
