//
//  maculateUITests.swift
//  maculateUITests
//
//  Created by Evan Boehs on 11/21/24.
//

import XCTest

final class maculateUITests: XCTestCase {

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
    func testReturnSubmitsSuccessiveCalculations() throws {
        let app = XCUIApplication()
        app.launch()
#if os(iOS)
        let field = app.textFields["expressionField"]
#else
        let field = app.textFields["Enter an expression"]
#endif
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("12345+67890\n")
        XCTAssertTrue(app.staticTexts["80235"].waitForExistence(timeout: 5))
        XCTAssertTrue(["", "Enter an expression"].contains(field.value as? String ?? "<missing>"))

        // Return must retain focus so another calculation needs no extra tap.
        field.typeText("9876*5\n")
        XCTAssertTrue(app.staticTexts["49380"].waitForExistence(timeout: 5))
        XCTAssertTrue(["", "Enter an expression"].contains(field.value as? String ?? "<missing>"))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
