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

// Device QA: three cold launches, synthetic unsent drafts, no identity/consent changes.
extension RunnerUITests {
  func testThreeDeviceComposerRounds() throws {
    continueAfterFailure = false
    let qa = XCUIApplication(bundleIdentifier: "com.onaria.app")
    func target(_ label: String) -> XCUIElement {
      qa.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }
    for round in 1...3 {
      qa.terminate()
      Thread.sleep(forTimeInterval: 2.0)
      qa.launch()
      Thread.sleep(forTimeInterval: 1.0)
      XCTAssertTrue(qa.wait(for: .runningForeground, timeout: 15))
      XCTAssertTrue(target("메뉴").waitForExistence(timeout: 15))
      let feeling = qa.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "감사")).firstMatch
      var emotionConfirmed = false
      for attempt in 0..<4 {
        for _ in 0..<12 {
          if feeling.exists && feeling.isHittable && feeling.frame.minY > 110 && feeling.frame.maxY < qa.frame.maxY - 60 { break }
          if feeling.exists && feeling.frame.height > 1 && feeling.frame.width > 1 && feeling.frame.minY < 110 { qa.swipeDown(velocity: .slow) }
          else { qa.swipeUp(velocity: .slow) }
          Thread.sleep(forTimeInterval: 1.0)
        }
        XCTAssertTrue(feeling.exists && feeling.isHittable)
        let before = feeling.frame
        Thread.sleep(forTimeInterval: 0.8)
        if abs(feeling.frame.minY - before.minY) > 2 { continue }
        print("CARE_QA_EMOTION attempt=\(attempt) frame=\(feeling.frame)")
        feeling.tap()
        Thread.sleep(forTimeInterval: 1.0)
        emotionConfirmed = feeling.isSelected || feeling.label.contains("선택됨")
        if emotionConfirmed { break }
      }
      XCTAssertTrue(emotionConfirmed, "Gratitude selection must be acknowledged before continuing")
      let start = qa.buttons.matching(NSPredicate(format: "label CONTAINS %@", "대화 시작하기")).firstMatch
      for _ in 0..<6 {
        if start.exists && start.isHittable && start.frame.minY > 120 && start.frame.maxY < qa.frame.maxY - 40 { break }
        qa.swipeUp(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.8)
      }
      XCTAssertTrue(start.exists)
      XCTAssertTrue(start.isEnabled, "Emotion selection must enable conversation")
      Thread.sleep(forTimeInterval: 0.6)
      start.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      Thread.sleep(forTimeInterval: 0.8)
      let view = qa.textViews.firstMatch
      let field = qa.textFields.firstMatch
      XCTAssertTrue(view.waitForExistence(timeout: 10) || field.exists)
      let editor = view.exists ? view : field
      XCTAssertTrue(target("보내기").exists)
      XCTAssertTrue(target("음성으로 마음 말하기").exists)
      let idle = XCTAttachment(screenshot: qa.screenshot())
      idle.name = "composer-idle-round-\(round)"
      idle.lifetime = .keepAlways
      add(idle)
      editor.tap()
      XCTAssertTrue(qa.keyboards.firstMatch.waitForExistence(timeout: 5))
      editor.typeText("QA gratitude draft \(round)")
      XCTAssertTrue((editor.value as? String ?? "").contains("QA gratitude draft"))
      XCTAssertTrue(target("보내기").exists)
      let focused = XCTAttachment(screenshot: qa.screenshot())
      focused.name = "composer-focused-round-\(round)"
      focused.lifetime = .keepAlways
      add(focused)
      print("CARE_DEVICE_ROUND \(round) COMPOSER_KEYBOARD_DRAFT_PASS")
      qa.terminate()
    }
  }
}

extension RunnerUITests {
  func testThreeDeviceGameRounds() throws {
    continueAfterFailure = false
    let qa = XCUIApplication(bundleIdentifier: "com.onaria.app")
    func exact(_ label: String) -> XCUIElement {
      qa.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }
    func tapVisible(_ label: String) {
      let element = exact(label)
      for _ in 0..<10 {
        if element.exists && element.isHittable && element.frame.minY >= 60 && element.frame.maxY < qa.frame.maxY - 34 { break }
        qa.swipeUp(velocity: .slow)
        Thread.sleep(forTimeInterval: 0.8)
      }
      XCTAssertTrue(element.exists && element.isHittable)
      Thread.sleep(forTimeInterval: 0.6)
      element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      Thread.sleep(forTimeInterval: 0.8)
    }
    for round in 1...3 {
      qa.terminate()
      Thread.sleep(forTimeInterval: 2)
      qa.launch()
      XCTAssertTrue(qa.wait(for: .runningForeground, timeout: 15))
      XCTAssertTrue(exact("메뉴").waitForExistence(timeout: 15))
      tapVisible("메뉴")
      Thread.sleep(forTimeInterval: 1.2)
      tapVisible("십자가 미니게임")
      let heading = qa.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "빛 조각으로 십자가")).firstMatch
      XCTAssertTrue(heading.waitForExistence(timeout: 10))
      let back = exact("Back").exists ? exact("Back") : exact("뒤로")
      XCTAssertTrue(back.waitForExistence(timeout: 5))
      let game = XCTAttachment(screenshot: qa.screenshot())
      game.name = "game-entry-round-\(round)"
      game.lifetime = .keepAlways
      add(game)
      back.tap()
      XCTAssertTrue(exact("메뉴").waitForExistence(timeout: 10))
      let home = XCTAttachment(screenshot: qa.screenshot())
      home.name = "game-return-round-\(round)"
      home.lifetime = .keepAlways
      add(home)
      print("CARE_GAME_ROUND \(round) ENTRY_RETURN_PASS")
      qa.terminate()
    }
  }
}
