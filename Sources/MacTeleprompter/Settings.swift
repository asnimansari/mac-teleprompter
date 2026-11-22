import Foundation

enum PanelSize: String, CaseIterable {
    case small, medium, large

    var label: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    /// Size of the text area below the notch.
    var size: CGSize {
        switch self {
        case .small: CGSize(width: 360, height: 110)
        case .medium: CGSize(width: 420, height: 140)
        case .large: CGSize(width: 520, height: 190)
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: 18
        case .medium: 22
        case .large: 28
        }
    }
}

@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()
    static let wpmRange = 80...220

    private let defaults = UserDefaults.standard

    @Published var script: String { didSet { defaults.set(script, forKey: "script") } }
    @Published var wpm: Int { didSet { defaults.set(wpm, forKey: "wpm") } }
    @Published var size: PanelSize { didSet { defaults.set(size.rawValue, forKey: "size") } }
    @Published var countdownEnabled: Bool { didSet { defaults.set(countdownEnabled, forKey: "countdown") } }

    private init() {
        defaults.register(defaults: ["wpm": 140, "size": PanelSize.medium.rawValue, "countdown": true])
        script = defaults.string(forKey: "script") ?? ""
        wpm = defaults.integer(forKey: "wpm")
        size = PanelSize(rawValue: defaults.string(forKey: "size") ?? "") ?? .medium
        countdownEnabled = defaults.bool(forKey: "countdown")
    }
}
