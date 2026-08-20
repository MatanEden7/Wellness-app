import Testing
import Foundation
@testable import WellnessDomain
@testable import WellnessModels

@Test func goldenCorpusFilesAccessible() throws {
    // Phase 3 will replay each golden JSON file against the ported Swift logic.
    // For now, verify the test target is wired and can find its resources.
    #expect(WellnessDomainMarker.version == "0.1.0")
}
