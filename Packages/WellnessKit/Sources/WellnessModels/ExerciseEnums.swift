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
