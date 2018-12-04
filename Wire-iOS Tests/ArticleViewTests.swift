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


import XCTest
import WireLinkPreview
@testable import Wire

class ArticleViewTests: ZMSnapshotTestCase {
    
    var sut: ArticleView!
        
    override func tearDown() {
        
        defaultImageCache.cache.removeAllObjects()
        sut = nil
        super.tearDown()
    }
        
    /// MARK - Fixture
    
    func articleWithoutPicture() -> MockTextMessageData {
        let article = ArticleMetadata(originalURLString: "https://www.example.com/article/1",
                              permanentURLString: "https://www.example.com/article/1",
                              resolvedURLString: "https://www.example.com/article/1",
                              offset: 0)
        
        article.title = "Title with some words in it"
        article.summary = "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"
        
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = article
        return textMessageData
    }
    
    func articleWithPicture(imageNamed: String = "unsplash_matterhorn.jpg") -> MockTextMessageData {
        let article = ArticleMetadata(originalURLString: "https://www.example.com/article/1",
                              permanentURLString: "https://www.example.com/article/1",
                              resolvedURLString: "https://www.example.com/article/1",
                              offset: 0)
        
        article.title = "Title with some words in it"
        article.summary = "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"
        
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id-\(imageNamed)"
        textMessageData.imageData = image(inTestBundleNamed: imageNamed).jpegData(compressionQuality: 0.9)
        textMessageData.linkPreviewHasImage = true
        
        return textMessageData
    }
    
    func articleWithLongURL() -> MockTextMessageData {
        let article = ArticleMetadata(originalURLString: "https://www.example.com/verylooooooooooooooooooooooooooooooooooooongpath/article/1/",
                              permanentURLString: "https://www.example.com/veryloooooooooooooooooooooooooooooooooooongpath/article/1/",
                              resolvedURLString: "https://www.example.com/veryloooooooooooooooooooooooooooooooooooongpath/article/1/",
                              offset: 0)
        
        article.title = "Title with some words in it"
        article.summary = "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"
        
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id"
        textMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        textMessageData.linkPreviewHasImage = true
        
        return textMessageData
    }
    
    func twitterStatusWithoutPicture() -> MockTextMessageData {
        let twitterStatus = TwitterStatusMetadata(
            originalURLString: "https://www.example.com/twitter/status/12345",
            permanentURLString: "https://www.example.com/twitter/status/12345/permanent",
            resolvedURLString: "https://www.example.com/twitter/status/12345/permanent",
            offset: 0
        )
        twitterStatus.author = "John Doe"
        twitterStatus.username = "johndoe"
        twitterStatus.message = "Message message message message message message message message message message message message message message message message message message"
        
        let textMessageData = MockTextMessageData()
        textMessageData.linkPreview = twitterStatus
        
        return textMessageData
    }
    
    /// MARK - Tests
    
    func testArticleViewWithoutPicture() {
        sut = ArticleView(withImagePlaceholder: false)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithoutPicture(), obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verifyInAllPhoneWidths(view: sut)
    }

    func testArticleViewWithPicture() {
        sut = ArticleView(withImagePlaceholder: true)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithPicture(), obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        self.verifyInAllPhoneWidths(view: self.sut)
    }
        
    func testArticleViewWithPictureStillDownloading() {
        
        sut = ArticleView(withImagePlaceholder: true)
        sut.layer.speed = 0 // freeze animations for deterministic tests
        sut.layer.beginTime = 0
        sut.translatesAutoresizingMaskIntoConstraints = false
        let textMessageData = articleWithPicture()
        textMessageData.imageData = .none
        sut.configure(withTextMessageData: textMessageData, obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verifyInAllPhoneWidths(view: sut)
    }
    
    func testArticleViewWithTruncatedURL() {
        sut = ArticleView(withImagePlaceholder: true)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithLongURL(), obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        self.verifyInAllPhoneWidths(view: self.sut)
    }
    
    func testArticleViewWithTwitterStatusWithoutPicture() {
        sut = ArticleView(withImagePlaceholder: false)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: twitterStatusWithoutPicture(), obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        verifyInAllPhoneWidths(view: sut)
    }

    func testArticleViewObfuscated() {
        sut = ArticleView(withImagePlaceholder: true)
        sut.layer.speed = 0
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithPicture(), obfuscated: true)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))

        verifyInAllPhoneWidths(view: sut)
    }
    
    /// MARK: - ArticleView images aspect
    
    func testArticleViewWithImageHavingSmallSize() {
        self.createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_size.jpg")
    }
    
    func testArticleViewWithImageHavingSmallHeight() {
        self.createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_height.jpg")
    }
    
    func testArticleViewWithImageHavingSmallWidth() {
        self.createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_width.jpg")
    }
    
    func testArticleViewWithImageHavingExactSize() {
        self.createTestForArticleViewWithImage(named: "unsplash_matterhorn_exact_size.jpg")
    }
    
    func createTestForArticleViewWithImage(named: String) {
        sut = ArticleView(withImagePlaceholder: true)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithPicture(imageNamed: named), obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([defaultImageCache.dispatchGroup]))
        
        self.verifyInAllPhoneWidths(view: self.sut)
    }
}
