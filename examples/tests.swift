import XCTest

// Should receive an `opening_brace` warning
class SimpleTests: XCTestCase
{
  var value: Int = 0

  override func setUp() {
    value = 4
  }

  func testThatWillSucceed() {
    XCTAssertEqual(value, 4)
  }
}
