import Foundation

public enum Equipment: String, Codable, Sendable, CaseIterable {
    case bodyweight, dumbbells, barbellRack, machines
    case bands, kettlebells, cable, pullupBar

    public var profileId: String {
        switch self {
        case .bodyweight:   "none"
        case .dumbbells:    "dumbbells"
        case .barbellRack:  "barbell_rack"
        case .machines:     "machines"
        case .bands:        "bands"
        case .kettlebells:  "kettlebells"
        case .cable:        "cable"
        case .pullupBar:    "pullup_bar"
        }
    }

    public static func forProfileId(_ id: String) -> Equipment? {
        allCases.first { $0.profileId == id }
    }
}

public enum BodyPart: String, Codable, Sendable, CaseIterable {
    case shoulder, back, knee, ankle, elbow, hip, neck

    public var profileId: String { rawValue }

    public static func forProfileId(_ id: String) -> BodyPart? {
        BodyPart(rawValue: id)
    }

    public func label(_ language: AppLanguage) -> String {
        language == .hebrew ? labelHe : labelEn
    }

    public var labelEn: String {
        switch self {
        case .shoulder: "Shoulder"
        case .back:     "Back"
        case .knee:     "Knee"
        case .ankle:    "Ankle"
        case .elbow:    "Elbow"
        case .hip:      "Hip"
        case .neck:     "Neck"
        }
    }

    public var labelHe: String {
        switch self {
        case .shoulder: "כתף"
        case .back:     "גב"
        case .knee:     "ברך"
        case .ankle:    "קרסול"
        case .elbow:    "מרפק"
        case .hip:      "ירך"
        case .neck:     "צוואר"
        }
    }
}

public enum MovementPattern: String, Codable, Sendable, CaseIterable {
    case squat, hinge, lunge
    case horizontalPush, verticalPush
    case horizontalPull, verticalPull
    case carry, coreBrace, isolation
}

public enum Mechanic: String, Codable, Sendable, CaseIterable {
    case compound, isolation
}

public enum LoadClass: String, Codable, Sendable, CaseIterable {
    case squatPattern, deadliftPattern, benchPattern, pressPattern
    case accessory, none
}
