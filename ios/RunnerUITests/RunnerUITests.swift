import XCTest
final class RunnerUITests: XCTestCase {
  func testReleaseAccessibilityTree() throws {
    let app = XCUIApplication()
    app.launch()
    sleep(3)
    print("ONARIA_RELEASE_AX_BEGIN")
    print(app.debugDescription)
    print("ONARIA_RELEASE_AX_END")
    XCTAssertTrue(app.exists)
  }
}
