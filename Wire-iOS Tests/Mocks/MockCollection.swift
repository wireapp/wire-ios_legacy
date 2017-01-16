//
//  MockCollection.swift
//  Wire-iOS
//
//  Created by Vytis ⚪️ on 2017-01-11.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

@testable import Wire

final class MockCollection: NSObject, ZMCollection {

    static let onlyFilesCategory = CategoryMatch(including: .file, excluding: .video)

    let messages: [CategoryMatch : [ZMConversationMessage]]

    init(messages: [CategoryMatch : [ZMConversationMessage]]) {
        self.messages = messages
    }

    convenience init(fileMessages: [ZMConversationMessage]) {
        self.init(messages: [
            MockCollection.onlyFilesCategory : fileMessages
            ])
    }
    
    static var empty: MockCollection {
        return MockCollection(messages: [:])
    }
    
    func tearDown() { }
    
    func assets(for category: ZMCDataModel.CategoryMatch) -> [ZMConversationMessage] {
        return messages[category] ?? []
    }
    
    let fetchingDone = true
}
