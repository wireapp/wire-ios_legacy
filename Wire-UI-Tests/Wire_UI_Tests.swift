//
//  Wire_iOS_UI_Tests.swift
//  Wire-iOS-UI-Tests
//
//  Created by Xue Qin on 1/11/18.
//  Copyright © 2018 Zeta Project Germany GmbH. All rights reserved.
//

import XCTest

// Private headers from XCTest


class Wire_UI_Tests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        sleep(5)
        
        if app.buttons["REGISTRATION"].exists {
            if app.buttons["CountryPickerButton"].exists { //not first time
                registeration()
                firstTimeLoginSuccess()
                if app.buttons["MANAGE DEVICES"].exists {
                    deleteDeviceAfterLogin()
                } else {
                    sleep(3)
                    if app.alerts["“Wire” Would Like to Send You Notifications"].exists {
                            sleep(2)
                            app.alerts["“Wire” Would Like to Send You Notifications"].buttons["Allow"].tap()
                    }
                    sleep(2)
                    app.buttons["OK"].tap()
                }
            } else {
                login()
            }
        }        
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        //Springboard.deleteMyApp()
        super.tearDown()
    }
    
    /**
     Scrolls to a particular element until it is rendered in the visible rect
     - Parameter elememt: the element we want to scroll to
     */
    func scrollToElement(element: XCUIElement)
    {
        while element.exists == false
        {
            app.swipeUp()
        }
        
        sleep(3)
    }
    
    
    func logout() {
        
        app.buttons["Profile"].tap()
        app.tables.staticTexts["Settings"].tap()
        app.tables.staticTexts["Account"].tap()
        app.swipeUp()
        let signout = app.tables.staticTexts.matching(identifier: "Sign Out").element(boundBy: 0)
        signout.tap()
    }
    
    func login() {
        
        let passwordfield = app.secureTextFields.matching(identifier: "PasswordField").element(boundBy: 0)
        passwordfield.typeText("utsa123456")
        app.buttons["RegistrationConfirmButton"].tap()
        sleep(3)
        app.buttons["OK"].tap()
    }
    
    func registeration() {
        
        let registrationButton = app.buttons["REGISTRATION"]
        
        registrationButton.tap()
        
        // step1: choose country
        app.buttons["CountryPickerButton"].tap()
        let searchField = app.tables.searchFields["Search"]
        searchField.tap()
        app.keyboards.keys["U"].tap()
        app.keyboards.keys["n"].tap()
        app.keyboards.keys["i"].tap()
        app.keyboards.keys["t"].tap()
        app.keyboards.keys["e"].tap()
        app.keyboards.keys["d"].tap()
        sleep(2)
        app.tables["Search results"].staticTexts["United States"].tap()
        
        // step2: enter phone number
        app.keyboards.keys["2"].tap()
        app.keyboards.keys["1"].tap()
        app.keyboards.keys["0"].tap()
        app.keyboards.keys["4"].tap()
        app.keyboards.keys["5"].tap()
        app.keyboards.keys["8"].tap()
        app.keyboards.keys["5"].tap()
        app.keyboards.keys["7"].tap()
        app.keyboards.keys["2"].tap()
        app.keyboards.keys["0"].tap()
        app.buttons["RegistrationConfirmButton"].tap()
        
        // step3: enter verification code
        let verificationfieldTextField = app.textFields["verificationField"]
        verificationfieldTextField.tap()
        verificationfieldTextField.typeText("000000")
        app.buttons["RegistrationConfirmButton"].tap()
        sleep(2)
        app.alerts.buttons["OK"].tap()
        sleep(2)
        //return to main page
        app.buttons["BackToWelcomeButton"].tap()
        sleep(3)
    }
    
    /*
    func testFailedLogin() {
        
        //logout()
        
        let app = XCUIApplication()
        app.textFields["EmailField"].tap()
        
        let passwordfield = app.secureTextFields.matching(identifier: "PasswordField").element(boundBy: 0)
        // login with wrong password
        passwordfield.tap()
        passwordfield.typeText("utsa123")
        app.buttons["RegistrationConfirmButton"].tap()
        sleep(3)
        app.alerts.buttons["OK"].tap()
        
        // forget password
        app.buttons["FORGOT PASSWORD?"].tap()
        
    }
 */
    
    func firstTimeLoginSuccess() {
        
        app.buttons["LOG IN"].tap()
        let emailbutton = app.buttons["EMAIL"]
        let emailfiled = app.textFields["EmailField"]
        let passwordfield = app.secureTextFields.matching(identifier: "PasswordField").element(boundBy: 0)
        
        // login with valid email and password
        emailbutton.tap()
        emailfiled.tap()
        emailfiled.typeText("ui.privacy.utsa@gmail.com")
        passwordfield.tap()
        passwordfield.typeText("utsa123456")
        app.buttons["RegistrationConfirmButton"].tap()
        sleep(3)
        
    }
    
    func deleteDeviceAfterLogin() {
        app.buttons["MANAGE DEVICES"].tap()
        app.tables.cells.containing(.staticText, identifier:"Simulator").element(boundBy: 0).swipeLeft()
        app.tables.cells.containing(.staticText, identifier:"Delete").element(boundBy: 0).tap()
        sleep(3)
        if app.alerts["“Wire” Would Like to Send You Notifications"].exists {
            sleep(2)
            app.alerts["“Wire” Would Like to Send You Notifications"].buttons["Allow"].tap()
        }
        sleep(2)
        app.buttons["OK"].tap()
        
        
    }
    

    
    
    
    
    
}
