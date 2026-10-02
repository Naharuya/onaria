import XCTest
final class RunnerUITests: XCTestCase {
  func testAccountDeletionEntry() throws {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

    print("ONARIA_AX_BEGIN")
    print(app.debugDescription)
    print("ONARIA_AX_END")
    let menu = app.descendants(matching: .any).matching(identifier: "메뉴").firstMatch
    XCTAssertTrue(menu.waitForExistence(timeout: 10))
    menu.tap()
    var privacy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "개인정보·회원탈퇴")).firstMatch
    if !privacy.waitForExistence(timeout: 2) {
      menu.tap()
      privacy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "개인정보·회원탈퇴")).firstMatch
    }
    print("ONARIA_MENU_AX_BEGIN")
    print(app.debugDescription)
    print("ONARIA_MENU_AX_END")
    XCTAssertTrue(privacy.waitForExistence(timeout: 5))
    privacy.tap()
    XCTAssertTrue(app.staticTexts["개인정보와 기록 관리"].waitForExistence(timeout: 5))

    for _ in 0..<5 {
      if app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "본인인증 설정 후 회원탈퇴 가능")).firstMatch.exists { break }
      app.swipeUp()
    }
    XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "본인인증 설정 후 회원탈퇴 가능")).firstMatch.exists)
    for _ in 0..<4 {
      if app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "웹에서 계정 삭제 안내 보기")).firstMatch.exists { break }
      app.swipeUp()
    }
    XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "웹에서 계정 삭제 안내 보기")).firstMatch.exists)
  }

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
