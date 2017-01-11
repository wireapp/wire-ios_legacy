//
//  MockCollection.swift
//  Wire-iOS
//
//  Created by Vytis ⚪️ on 2017-01-11.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

@testable import Wire

class MockCollection: NSObject, ZMCollection {
    
    static var empty: MockCollection {
        return MockCollection()
    }
    
    func tearDown() { }
    
    func assets(for category: ZMCDataModel.CategoryMatch) -> [ZMMessage] {
        return []
    }
    
    let fetchingDone = true
}
