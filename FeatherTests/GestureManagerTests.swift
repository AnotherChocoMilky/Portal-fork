import XCTest
@testable import Feather

final class GestureManagerTests: XCTestCase {
    var gestureManager: GestureManager!

    override func setUp() {
        super.setUp()
        gestureManager = GestureManager.shared
        // Reset mappings for testing
        gestureManager.mappings = [:]
    }

    func testSetAndGetMapping() {
        let section: AppSection = .library
        let gesture: GestureType = .doubleTap
        let action: GestureAction = .signApp

        gestureManager.setMapping(for: gesture, in: section, action: action)

        let retrievedAction = gestureManager.getAction(for: gesture, in: section)
        XCTAssertEqual(retrievedAction, action)
    }

    func testDefaultMappings() {
        gestureManager.loadMappings()
        let libraryAction = gestureManager.getAction(for: .leftSwipe, in: .library)
        XCTAssertEqual(libraryAction, .deleteApp)
    }

    func testIsDestructive() {
        XCTAssertTrue(GestureAction.deleteApp.isDestructive)
        XCTAssertFalse(GestureAction.openDetails.isDestructive)
    }
}
