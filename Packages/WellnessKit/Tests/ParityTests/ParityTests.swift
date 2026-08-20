import Testing
import Foundation
@testable import WellnessDomain
@testable import WellnessModels

@Test func goldenCorpusFilesAccessible() throws {
    // Phase 3 will replay each golden JSON file against the ported Swift logic.
    // For now, verify the test target is wired and can import domain types.
    let t = SetupEngine.calculateTargets(
        sex: "male", weightKg: 80, heightCm: 180,
        ageYears: 30, goal: "maintenance", activityLevel: "moderate"
    )
    #expect(t.bmr > 0)
}
