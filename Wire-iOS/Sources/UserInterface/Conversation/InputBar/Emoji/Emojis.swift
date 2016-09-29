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


typealias Emoji = String

class EmojiDataSource: NSObject, UICollectionViewDataSource {
    
    typealias CellProvider = (Emoji, IndexPath) -> UICollectionViewCell
    
    private let sections: [EmojiSection]
    let cellProvider: CellProvider
    
    
    init(provider: @escaping CellProvider) {
        cellProvider = provider
        sections = EmojiSectionType.all.flatMap(EmojiSection.init)
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self[section].emoji.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(self[indexPath], indexPath)
    }
    
    subscript (index: Int) -> EmojiSection {
        return sections[index]
    }
    
    subscript (indexPath: IndexPath) -> Emoji {
        return sections[indexPath.section][indexPath.item]
    }
    
    func sectionIndex(for type: EmojiSectionType) -> Int? {
        return sections.map { $0.type }.index(of: type)
    }
    
}


enum EmojiSectionType: String {

    case people, nature, food, travel, activities, objects, symbols, flags

    var icon: ZetaIconType {
        switch self {
        case .people: return .emoji
        case .nature: return .flower
        case .food: return .cake
        case .travel: return .car
        case .activities: return .ball
        case .objects: return .crown
        case .symbols: return .asterisk
        case .flags: return .flag
        }
    }

    static var all: [EmojiSectionType] {
        return [
            EmojiSectionType.people,
            .nature,
            .food,
            .travel,
            .activities,
            .objects,
            .symbols,
            .flags
        ]
    }

}

struct EmojiSection {
    
    init?(_ type: EmojiSectionType) {
        let filename = "emoji_\(type.rawValue)"
        guard let url = Bundle.main.url(forResource: filename, withExtension: "plist") else { return nil }
        guard let emoji = NSArray(contentsOf: url) as? [Emoji] else { return nil }
        self.emoji = emoji
        self.type = type
    }
    
    let emoji: [Emoji]
    let type: EmojiSectionType
    
    subscript(index: Int) -> Emoji {
        return emoji[index]
    }
}

