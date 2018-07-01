//
//  SavourDealsUITests.swift
//  SavourDealsUITests
//
//  Created by Chris Patterson on 6/22/18.
//  Copyright © 2018 Chris Patterson. All rights reserved.
//

import XCTest

class SavourDealsUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        snapshot("launch")
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let app = XCUIApplication()
//        let emailexists = NSPredicate(format: "exists == true")
//        expectation(for: emailexists, evaluatedWith:  app/*@START_MENU_TOKEN@*/.textFields["email"]/*[[".textFields[\"Email\"]",".textFields[\"email\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/, handler: nil)
//        waitForExpectations(timeout: 5, handler: nil)
//        let emailTextField = app/*@START_MENU_TOKEN@*/.textFields["email"]/*[[".textFields[\"Email\"]",".textFields[\"email\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        emailTextField.tap()
//        emailTextField.typeText("test@test.com")
//        let passexists = NSPredicate(format: "exists == true")
//        expectation(for: passexists, evaluatedWith:  app/*@START_MENU_TOKEN@*/.secureTextFields["password"]/*[[".secureTextFields[\"Password\"]",".secureTextFields[\"password\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/, handler: nil)
//        waitForExpectations(timeout: 5, handler: nil)
//        let pass = app/*@START_MENU_TOKEN@*/.secureTextFields["password"]/*[[".secureTextFields[\"Password\"]",".secureTextFields[\"password\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        pass.tap()
//        pass.typeText("123456")
//        app/*@START_MENU_TOKEN@*/.buttons["login"]/*[[".buttons[\"Login\"]",".buttons[\"login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let tabBarsQuery = app.tabBars
        // deals
        tabBarsQuery.buttons.element(boundBy: 0).tap()
        // Here, we'll take the first screenshot
        sleep(10)
        snapshot("0-deals")
        app.tableRows.element(boundBy: 1).tap()
        sleep(5)
        snapshot("DealPage")
        app.navigationBars.buttons.element(boundBy: 0).tap()


//         favs
        tabBarsQuery.buttons.element(boundBy: 1).tap()
        // Here, we'll take the second screenshot
        // After pressing the "eventlocation" annotation on the map.
        snapshot("1-favs")
        sleep(5)


        // vendors
        tabBarsQuery.buttons.element(boundBy: 2).tap()
        // Here, we'll take the third screenshot
        snapshot("2-vendors")
        sleep(5)

    }
    
}
