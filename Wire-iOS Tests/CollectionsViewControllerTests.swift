//
//  CollectionsViewControllerTests.swift
//  Wire-iOS
//
//  Created by Vytis ⚪️ on 2017-01-11.
//  Copyright © 2017 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest
import Cartography
@testable import Wire

class MockCollection: NSObject, ZMCollection {
    func tearDown() { }
    
    func assets(for category: ZMCDataModel.CategoryMatch) -> [ZMMessage] {
        return []
    }

    let fetchingDone = true
}

class CollectionsViewControllerTests: ZMSnapshotTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatNoElementStateIsShownWhenCollectionIsEmpty() {
        let conversation = MockConversation() as Any as! ZMConversation
        let assetCollection = MockCollection()
        let delegate = AssetCollectionMulticastDelegate()
        let collection = AssetCollectionWrapper(conversation: conversation, assetCollection: assetCollection, assetCollectionDelegate: delegate)
        
        let controller = CollectionsViewController(collection: collection, fetchingDone: true)
        verifyInAllIPhoneSizes(view: controller.view)
    }
}

private extension UIViewController {
    func prepareForSnapshot() -> UIView {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
        return view
    }
}
