//
//  ConversationsTest.swift
//  Wire-iOS
//
//  Created by Xue Qin on 1/18/18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest

class ConversationsTest: Wire_UI_Tests {
    
    func testAddConversation() {
        app.buttons["bottomBarPlusButton"].tap()
        sleep(5)
        if app.alerts["“Wire” Would Like to Access Your Contacts"].exists {
            app.alerts["“Wire” Would Like to Access Your Contacts"].buttons["OK"].tap()
        }
        sleep(1)
        app.collectionViews.staticTexts["Michelle"].tap()
        sleep(2)
        app.buttons["OPEN"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
        
    }
    
    func testOpenConversation() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendText() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.textViews["inputField"].typeText("Hi")
        app.buttons["sendButton"].tap()
        
        app.buttons["markdownButton"].tap()
        /*
        let element = app.windows["ZClientMainWindow"]
        element.children(matching: .button).element(boundBy: 0).tap()
        element.children(matching: .button).element(boundBy: 1).tap()
        element.children(matching: .button).element(boundBy: 2).tap()
        element.children(matching: .button).element(boundBy: 3).tap()
        element.children(matching: .button).element(boundBy: 4).tap()
        element.children(matching: .button).element(boundBy: 5).tap()
        */
        let inputfieldTextView = app.textViews["inputField"]
        inputfieldTextView.typeText("bye")
        app.buttons["sendButton"].tap()
        sleep(2)
        
        // return
        app.buttons["markdownButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
 
    }
    
    func testSendMarkedText() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.textViews["inputField"].typeText("Hello")
        
        app.buttons["markdownButton"].tap()
        
        let element = app.windows["ZClientMainWindow"].children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element(boundBy: 3).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element
        element.children(matching: .button).element(boundBy: 0).tap()
        element.children(matching: .button).element(boundBy: 1).tap()
        element.children(matching: .button).element(boundBy: 2).tap()
        element.children(matching: .button).element(boundBy: 3).tap()
        element.children(matching: .button).element(boundBy: 4).tap()
        element.children(matching: .button).element(boundBy: 5).tap()
        
        app.buttons["sendButton"].tap()
        // return
        app.buttons["markdownButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
        
    }
    
    func testSendPicture() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.buttons["photoButton"].tap()
        sleep(5)
        if app.alerts["“Wire” Would Like to Access your Photos"].exists {
            sleep(2)
            app.alerts["“Wire” Would Like to Access your Photos"].buttons["OK"].tap()
        }
        
        let collectionViewsQuery = app.collectionViews.cells
        collectionViewsQuery.children(matching: .other).element(boundBy: 1).tap()
        app.buttons["OK"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendSketch() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        let typeAMessageStaticText = app.textViews["inputField"].staticTexts["TYPE A MESSAGE"]
        typeAMessageStaticText.tap()
        
        let sketchbuttonButton = app.buttons["sketchButton"]
        sketchbuttonButton.tap()
        
        let collectionViewsQuery = app.collectionViews.cells
        collectionViewsQuery.children(matching: .other).element(boundBy: 4).tap()
        
        app.buttons["emojiButton"].tap()
        app.collectionViews.staticTexts["😀"].tap()
        app.buttons["sendButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendGif() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.windows["ZClientMainWindow"].children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).tap()
        app.buttons["gifButton"].tap()
        app.collectionViews["giphyCollectionView"].cells.children(matching: .other).element(boundBy: 4).tap()
        sleep(2)
        app.buttons["SEND"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendVoice() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.buttons["audioButton"].tap()
        app.buttons["record"].tap()
        sleep(4)
        app.buttons["stopRecording"].tap()
        
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.cells["None"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Helium"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Jellyfish"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Hare"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Cathedral"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Alien"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["VocoderMed"].children(matching: .other).element.tap()
        collectionViewsQuery.cells["Roller coaster"].children(matching: .other).element.tap()
        sleep(1)
        app.buttons["confirmRecording"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendPing() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.buttons["showOtherRowButton"].tap()
        app.buttons["pingButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testUploadFile() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["Record a video"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["Videos"].tap()
        app.navigationBars["Photos"].buttons["Cancel"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["20 MB file"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["Big file"].tap()
        sleep(2)
        app.alerts.buttons["OK"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["group-icon@3x.png"].tap()
        
        app.buttons["showOtherRowButton"].tap()
        app.buttons["uploadFileButton"].tap()
        app.tables.staticTexts["CountryCodes.plist"].tap()
        
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testMessageTimer() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.buttons["ephemeralTimeSelectionButton"].tap()
        let timerpicker = app.pickerWheels.element(boundBy: 0)
        timerpicker.adjust(toPickerWheelValue: "5 seconds")
        app.textViews["inputField"].staticTexts["TIMED MESSAGE"].tap()
        let inputfieldTextView = app.textViews["inputField"]
        inputfieldTextView.typeText("Bye")
        app.buttons["sendButton"].tap()
        
        sleep(8)
        
        app.buttons.matching(identifier: "5").element(boundBy: 0).tap()
        timerpicker.adjust(toPickerWheelValue: "Off")
        app.buttons["ephemeralTimeSelectionButton"].tap()
        sleep(3)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(3)
        
    }
    
    func testUserControls() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.navigationBars["MICHELLE"].otherElements["Name"].tap()
        app.buttons["DEVICES"].tap()
        
        /*
        app.tables.staticTexts["DESKTOP"].tap()
        app.buttons["show my device"].tap()
        app.navigationBars["Phone"].buttons["Done"].tap()
        app.switches["device verified"].tap()
        app.buttons["back"].tap()
        */
        sleep(2)
        app.buttons["DETAILS"].tap()
        
        let otherusermetacontrollerrightbuttonButton = app.buttons["OtherUserMetaControllerRightButton"]
        otherusermetacontrollerrightbuttonButton.tap()
        app.buttons["MUTE"].tap()
        otherusermetacontrollerrightbuttonButton.tap()
        app.buttons["UNMUTE"].tap()
        
        app.buttons["OtherUserProfileCloseButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
        
    }
    
    func testBlockAndUnblockUser() {
        //block
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.navigationBars["MICHELLE"].otherElements["Name"].tap()
        let otherusermetacontrollerrightbuttonButton = app.buttons["OtherUserMetaControllerRightButton"]
        otherusermetacontrollerrightbuttonButton.tap()
        app.buttons["BLOCK"].tap()
        
        sleep(2)
        let confirmBlockButton = app.buttons.matching(identifier: "BLOCK").element(boundBy: 0)
        confirmBlockButton.tap()

        //unblock
        app.buttons["bottomBarPlusButton"].tap()
        sleep(2)
        app.textViews["SEARCH BY NAME OR USERNAME"].staticTexts["SEARCH BY NAME OR USERNAME"].tap()
        let textviewsearchTextView = app.textViews["textViewSearch"]
        sleep(3)
        textviewsearchTextView.typeText("Michelle82")
        sleep(2)
        app.collectionViews.staticTexts["@michelle82"].tap()
        sleep(2)
        app.buttons["UNBLOCK"].tap()
        sleep(5)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    /*
    func testArchiveAndUnarchiveUser() {
        
        
        //archive
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.navigationBars["MICHELLE"].otherElements["Name"].tap()
        let otherusermetacontrollerrightbuttonButton = app.buttons["OtherUserMetaControllerRightButton"]
        otherusermetacontrollerrightbuttonButton.tap()
        app.buttons["OtherUserMetaControllerRightButton"].tap()
        sleep(5)
        let archiveButton = app.staticTexts["ARCHIVE"]
        sleep(4)
        archiveButton.tap()
        sleep(3)
        
        //unarchive
        app.buttons["bottomBarArchivedButton"].tap()
        app.collectionViews["archived conversation list"].buttons["Michelle"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(1)
 
    }
 */
    /*
    func testDeleteAndAdd() {
        
    }
 */
    
    func testCallingUser() {
        
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["videoCallBarButton"].tap()
        sleep(5)
        if app.alerts["“Wire” Would Like to Access the Camera"].exists {
            sleep(2)
            app.alerts["“Wire” Would Like to Access the Camera"].buttons["OK"].tap()
        }
        sleep(5)
        app.buttons["LeaveCallButton"].tap()
        sleep(3)
        app.navigationBars["MICHELLE"].buttons["audioCallBarButton"].tap()
        sleep(5)
        app.buttons["CallSpeakerButton"].tap()
        sleep(2)
        app.buttons["LeaveCallButton"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testCreateGroup() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.navigationBars["MICHELLE"].otherElements["Name"].tap()
        app.buttons["CREATE GROUP"].tap()
        sleep(2)
        app.buttons["Create group"].tap()
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
    
    func testSendSubject() {
        
        app.buttons["compose"].tap()
        let messagetextfieldTextView = app.textViews["messageTextField"]
        messagetextfieldTextView.tap()
        messagetextfieldTextView.typeText("Test")
        app.buttons["sendButton"].tap()
        app.tables.staticTexts["Michelle"].tap()
        app.buttons["send"].tap()
    }
    
    func testInviteContact() {
        
        app.buttons["bottomBarPlusButton"].tap()
        app.buttons["INVITE MORE PEOPLE"].tap()
        app.tables.cells.containing(.staticText, identifier:"Anna Haro").buttons["INVITE"].tap()
        sleep(2)
        app.alerts.buttons["OK"].tap()
        
    }
    
    
    func testInviteAndCancel() {
        
        //invite
        app.buttons["contacts"].tap()
        app.textViews["SEARCH BY NAME OR USERNAME"].staticTexts["SEARCH BY NAME OR USERNAME"].tap()
        let textviewsearchTextView = app.textViews["textViewSearch"]
        textviewsearchTextView.typeText("Test27")
        app.collectionViews.staticTexts["@test27"].tap()
        sleep(2)
        app.buttons["CONNECT"].tap()
        sleep(2)
        app.buttons["close"].tap()
        
        //cancel
        app.collectionViews["conversation list"].buttons["Test"].tap()
        app.buttons["cancel connection"].tap()
        
        sleep(4)
        
    }
    
    func testTextSearch() {
        app.collectionViews["conversation list"].buttons["Michelle"].tap()
        app.textViews["inputField"].staticTexts["TYPE A MESSAGE"].tap()
        app.textViews["inputField"].typeText("Hi")
        app.buttons["sendButton"].tap()
        
        
        app.navigationBars["MICHELLE"].buttons["collection"].tap()
        let searchInputTextField = app.textFields["search input"]
        searchInputTextField.tap()
        searchInputTextField.typeText("Hi")
        
        app.tables.children(matching: .cell).matching(identifier: "search result cell").element(boundBy: 0).tap()
        sleep(2)
        // return
        sleep(2)
        app.navigationBars["MICHELLE"].buttons["ConversationBackButton"].tap()
        sleep(2)
        app.buttons["bottomBarSettingsButton"].tap()
        sleep(4)
    }
 
    
}
