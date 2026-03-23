//
//  Chit_ChatUITests.swift
//  Chit ChatUITests
//
//  Created by Brian Bruce on 2025-06-24.
//

import XCTest

final class Chit_ChatUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        let welcomeVisible = app.staticTexts["Welcome to Chit Chat"].waitForExistence(timeout: 12)
        let homeVisible = app.buttons["Home"].waitForExistence(timeout: 2)
        XCTAssertTrue(welcomeVisible || homeVisible)
    }

    @MainActor
    func testLoginFieldsArePresent() throws {
        let app = XCUIApplication()
        app.launch()

        let usernameField = app.textFields["username (required)"]
        let passwordField = app.secureTextFields["password (required)"]
        let loginButton = app.buttons["Log in"]
        let createButton = app.buttons["Create account"]

        let onLoginScreen = usernameField.waitForExistence(timeout: 12)
        if onLoginScreen {
            XCTAssertTrue(passwordField.exists)
            XCTAssertTrue(loginButton.exists || createButton.exists)
        } else {
            // Session may restore directly into the app shell.
            XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
