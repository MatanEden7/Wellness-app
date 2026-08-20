import Foundation

public enum TemplateOrigin: String, Codable, Sendable, CaseIterable {
    case builtin, generated, user

    public static func fromKey(_ raw: String?) -> TemplateOrigin {
        raw.flatMap(TemplateOrigin.init(rawValue:)) ?? .user
    }
}
