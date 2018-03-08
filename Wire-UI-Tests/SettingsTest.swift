//
//  SettingsTest.swift
//  Wire-iOS
//
//  Created by Xue Qin on 1/11/18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest

class ProfileTest: Wire_UI_Tests {
    
    func testAccountInfoAndAppearance() {
        
        //go to account
        app.buttons["bottomBarSettingsButton"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Account"].tap()
        
        // INFO
        app.tables.staticTexts["Username"].tap()
        sleep(2)
        app.navigationBars["Username"].buttons["Account"].tap()
        app.tables.staticTexts["Phone"].tap()
        sleep(2)
        app.navigationBars["Profile"].buttons["Account"].tap()
        app.tables.staticTexts["Email"].tap()
        sleep(2)
        app.navigationBars["Email"].buttons["Account"].tap()
        
        // Appearance Picture
        app.tables.staticTexts["Picture"].tap()
        app.buttons["CameraLibraryButton"].tap()
        sleep(2)
        if app.alerts["“Wire” Would Like to Access Your Photos"].exists {
            sleep(4)
            app.alerts["“Wire” Would Like to Access Your Photos"].buttons["OK"].tap()
        }
        
        app.tables.buttons["Camera Roll"].tap()
        app.collectionViews["PhotosGridView"].cells["Photo, Landscape, March 12, 2011, 6:17 PM"].tap()
        app.buttons["sketchButton"].tap()
        sleep(2)
        app.buttons["emojiButton"].tap()
        sleep(2)
        app.navigationBars["Wire.CanvasView"].buttons["closeButton"].tap()
        sleep(2)
        app.buttons["OK"].tap()
        app.buttons["CloseButton"].tap()
        
        // Appearance Color
        let colorStaticText = app.tables.staticTexts["Color"]
        colorStaticText.tap()
        
    }
    
    func testAccountResetPassword() {
        
        //go to account
        app.buttons["bottomBarSettingsButton"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Account"].tap()
        
        app.tables.staticTexts["Reset Password"].tap()
    }
    
    func testAccountDeleteAccount() {
        
        //go to account
        app.buttons["bottomBarSettingsButton"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Account"].tap()
        
        app.tables.staticTexts["Delete Account"].tap()
        sleep(2)
        app.alerts["Delete Account"].buttons["Cancel"].tap()
    }
    
    func testOptions() {

        // goto Option
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Options"].tap()
        
        
        // notification
        // messagePreviews = tablesQuery.staticTexts.switches.matching(identifier: "Message Previews").element(boundBy: 0)
        app.tables.switches.matching(identifier: "1").element(boundBy: 0).tap()
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        
        // messageBanners = tablesQuery.staticTexts.matching(identifier:"Message Banners").element(boundBy: 0)
        app.tables.switches.matching(identifier: "1").element(boundBy: 1).tap()
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        
        app.tables.staticTexts["Sound Alerts"].tap()
        app.tables.staticTexts["None"].tap()
        app.tables.staticTexts["All"].tap()
        app.tables.staticTexts["First message, pings, calls"].tap()
        app.navigationBars["Sound Alerts"].buttons["Options"].tap()
        
        // calls
        // shareWithIos = tablesQuery.staticTexts.matching(identifier:"Share with iOS").element(boundBy: 0)
        app.tables.switches.matching(identifier: "1").element(boundBy: 2).tap()
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        
        app.tables.switches["VBRSwitch"].tap()
        
        // sounds
        let ringtone = app.tables.staticTexts["Ringtone"]
        scrollToElement(element: ringtone)
        ringtone.tap()
        app.navigationBars["Ringtone"].buttons["Options"].tap()
        
        let texttone = app.tables.staticTexts["Text Tone"]
        scrollToElement(element: texttone)
        texttone.tap()
        app.navigationBars["Text Tone"].buttons["Options"].tap()
        
        let ping = app.tables.staticTexts["Ping"]
        scrollToElement(element: ping)
        ping.tap()
        app.navigationBars["Ping"].buttons["Options"].tap()
        
        // by popular demand
        let darkTheme = app.tables.staticTexts.matching(identifier:"Dark Theme").element(boundBy: 0)
        scrollToElement(element: darkTheme)
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        
        /*
        et sendButton = tablesQuery.staticTexts.matching(identifier:"Send Button").element(boundBy: 0)
        scrollToElement(element: sendButton)
        app.tables.switches.matching(identifier: "1").element(boundBy: 1).tap()
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        
        let lockWithPasscode = tablesQuery.staticTexts.matching(identifier:"Lock With Passcode").element(boundBy: 0)
        scrollToElement(element: lockWithPasscode)
        app.tables.switches.matching(identifier: "0").element(boundBy: 0).tap()
        app.tables.switches.matching(identifier: "1").element(boundBy: 2).tap()
        
        let createPreviewsForLinksYouSend = tablesQuery.staticTexts.matching(identifier:"Create Previews For Links You Send").element(boundBy: 0)
        scrollToElement(element: createPreviewsForLinksYouSend)
        app.tables.switches.matching(identifier: "1").element(boundBy: 2).tap()
        app.tables.switches.matching(identifier: "0").element(boundBy: 1).tap()
 */
 
        // return to main page
        app.navigationBars["Options"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Profile"].tap()
        app.navigationBars["Profile"].buttons["close"].tap()
    }
    
    func testAdvanced() {
        
        // go to Advanced
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Advanced"].tap()
        
        // usage and crash reports
        let switch1 = app.tables.switches["1"]
        let switch0 = app.tables.switches["0"]
        if switch1.isEnabled {
            switch1.tap()
        } else {
            switch0.tap()
        }
        
        // troubleshooting
        app.tables.staticTexts["Calling Debug Report"].tap()
        app.tables.staticTexts["Send report to Wire"].tap()
        app.collectionViews.collectionViews.buttons["Copy"].tap()
        app.navigationBars["Technical Report"].buttons["Advanced"].tap()
        
        app.tables.staticTexts["Reset Push Notifications Token"].tap()
        sleep(2)
        app.alerts["Push token has been reset"].buttons["OK"].tap()
        
        app.tables.staticTexts["Version Technical Details"].tap()
        
    }
    
    func testSupportWireSupportWebsite() {
        // goto Suppor
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Support"].tap()
        
        app.tables.staticTexts["Wire Support Website"].tap()
    }
    
    func testSupportContactSupport() {
        // goto Suppor
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Support"].tap()
        
        app.tables.staticTexts["Contact Support"].tap()
    }
    
    func testSupportReportMisuse() {
        // goto Suppor
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Support"].tap()
        
        app.tables.staticTexts["Report Misuse"].tap()
    }
    
    func testAboutWireWebsite() {
        // goto About
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["About"].tap()
        
        app.tables.staticTexts["Wire Website"].tap()
    }
    
    func testTermsOfUse() {
        // goto About
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["About"].tap()
        
        app.tables.staticTexts["Terms of Use"].tap()
    }
    
    func testPrivacyPolicy() {
        // goto About
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["About"].tap()
        
        app.tables.staticTexts["Privacy Policy"].tap()
    }
    
    func testLicense() {
        // goto About
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["About"].tap()
        
        app.tables.staticTexts["License Information"].tap()
    }
    
    func testDeveloperOptions() {
        // goto Developer Options
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Developer Options"].tap()
        
        app.tables.staticTexts["Logging"].tap()
        app.tables.cells.buttons["Go!"].tap()
        sleep(2)
        app.alerts["Add explanation"].buttons["Send"].tap()
        sleep(2)
        app.alerts["DEBUG MESSAGE"].buttons["OK"].tap()
        sleep(2)
        app.navigationBars["options"].buttons["Developer Options"].tap()
        
        let tablesQuery = app.tables
        
        // disAVS = tablesQuery.staticTexts.matching(identifier: "Disable AVS (Restart needed)").element(boundBy: 0)
        tablesQuery.switches.matching(identifier: "0").element(boundBy: 0).tap()
        tablesQuery.switches.matching(identifier: "1").element(boundBy: 0).tap()
        
        // disUI = tablesQuery.staticTexts.matching(identifier: "Disable UI (Restart needed)").element(boundBy: 0)
        tablesQuery.switches.matching(identifier: "0").element(boundBy: 1).tap()
        tablesQuery.switches.matching(identifier: "1").element(boundBy: 0).tap()
        
        // disHockey = tablesQuery.staticTexts.matching(identifier: "Disable Hockey (Restart needed)").element(boundBy: 0)
        tablesQuery.switches.matching(identifier: "0").element(boundBy: 2).tap()
        
        // disAnalytics = tablesQuery.staticTexts.matching(identifier: "Disable Analytics (Restart needed)").element(boundBy: 0)
        tablesQuery.switches.matching(identifier: "0").element(boundBy: 2).tap()
        
        // useAsset = tablesQuery.staticTexts.matching(identifier: "Use AssetCollectionBatched").element(boundBy: 0)
        tablesQuery.switches.matching(identifier: "0").element(boundBy: 2).tap()
        
        app.tables.staticTexts["Send broken message"].tap()
        
        app.tables.staticTexts["Find first unread conversation"].tap()
        app.alerts.buttons["OK"].tap()
        
        app.tables.staticTexts["Share Database"].tap()
        app.buttons["Preview Content"].tap()
        app.navigationBars["store"].buttons["store.wiredatabase"].tap()
        app.navigationBars["store.wiredatabase"].buttons["Done"].tap()
        
        app.tables.staticTexts["Reload user interface"].tap()
    }
    
    func testDevices() {
        //go to Device
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Devices"].tap()
        
        if app.tables.cells.containing(.staticText, identifier:"Simulator").element(boundBy: 1).exists {
            app.tables.cells.containing(.staticText, identifier:"Simulator").element(boundBy: 1).tap()
            app.tables.switches["device verified"].tap()
        
            app.tables.staticTexts["Reset Session"].tap()
            app.alerts.buttons["OK"].tap()
        
            app.tables.staticTexts["Remove Device"].tap()
            let removeDeviceAlert = app.alerts["Remove Device"]
            let passwordSecureTextField = removeDeviceAlert.collectionViews.secureTextFields["Password"]
            passwordSecureTextField.tap()
            passwordSecureTextField.typeText("utsa123456")
            removeDeviceAlert.buttons["OK"].tap()
            sleep(2)
        }
    }
    
    func testInvitePeople() {
        //go to InvitePeople
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Invite people"].tap()
        
        let collectionViewsQuery = app.otherElements["ActivityListView"].collectionViews.collectionViews
        collectionViewsQuery.buttons["Copy"].tap()
        app.tables.staticTexts["Invite people"].tap()
    }
    
    
}

