import Foundation

public enum L10n {
    public static func tr(_ key: String, _ args: any CVarArg...) -> String {
        let format = Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        if args.isEmpty { return format }
        return String(format: format, arguments: args)
    }
}
