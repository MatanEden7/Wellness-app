import Foundation
import Testing
@testable import WellnessUI

@Suite("Localization parity")
struct LocalizationParityTests {

    private let xcstringsURL: URL? = Bundle.module.url(
        forResource: "Localizable",
        withExtension: "xcstrings"
    )

    private func loadCatalog() throws -> [String: Any] {
        let url = try #require(xcstringsURL)
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json["strings"] as! [String: Any]
    }

    @Test("Every key has both en and he translations")
    func everyKeyHasBothLanguages() throws {
        let strings = try loadCatalog()
        var missingHe: [String] = []
        var missingEn: [String] = []

        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else {
                missingEn.append(key)
                missingHe.append(key)
                continue
            }
            if localizations["en"] == nil { missingEn.append(key) }
            if localizations["he"] == nil { missingHe.append(key) }
        }

        #expect(missingEn.isEmpty, "Keys missing English: \(missingEn.sorted())")
        #expect(missingHe.isEmpty, "Keys missing Hebrew: \(missingHe.sorted())")
    }

    @Test("No empty translation values")
    func noEmptyValues() throws {
        let strings = try loadCatalog()
        var empties: [String] = []

        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else { continue }
            for (lang, locValue) in localizations {
                guard let loc = locValue as? [String: Any],
                      let unit = loc["stringUnit"] as? [String: Any],
                      let text = unit["value"] as? String else { continue }
                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    empties.append("\(key)[\(lang)]")
                }
            }
        }

        #expect(empties.isEmpty, "Empty translations: \(empties.sorted())")
    }

    @Test("Key count matches expected 915")
    func keyCount() throws {
        let strings = try loadCatalog()
        #expect(strings.count == 915, "Expected 915 keys, got \(strings.count)")
    }

    @Test("Format specifiers match between en and he")
    func formatSpecifiersParity() throws {
        let strings = try loadCatalog()
        let specPattern = try Regex("%(?:\\d+\\$)?[@dlfsu]|%(?:\\d+\\$)?ll[du]")
        var mismatches: [String] = []

        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any],
                  let enLoc = localizations["en"] as? [String: Any],
                  let enUnit = enLoc["stringUnit"] as? [String: Any],
                  let enText = enUnit["value"] as? String,
                  let heLoc = localizations["he"] as? [String: Any],
                  let heUnit = heLoc["stringUnit"] as? [String: Any],
                  let heText = heUnit["value"] as? String else { continue }

            let enSpecs = enText.matches(of: specPattern).map { String(enText[$0.range]) }.sorted()
            let heSpecs = heText.matches(of: specPattern).map { String(heText[$0.range]) }.sorted()

            if enSpecs != heSpecs {
                mismatches.append("\(key): en=\(enSpecs) he=\(heSpecs)")
            }
        }

        #expect(mismatches.isEmpty, "Format specifier mismatches: \(mismatches)")
    }
}
