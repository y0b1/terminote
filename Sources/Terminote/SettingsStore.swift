import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var theme: ThemeConfiguration
    @Published private(set) var savedThemes: [SavedTheme]

    @Published var showsLineNumbers: Bool {
        didSet { defaults.set(showsLineNumbers, forKey: "showsLineNumbers") }
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let maximumSavedThemes = 10

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsLineNumbers = defaults.bool(forKey: "showsLineNumbers")
        theme = Self.decode(
            ThemeConfiguration.self,
            from: defaults.data(forKey: "themeConfiguration")
        ) ?? .default
        savedThemes = Self.decode(
            [SavedTheme].self,
            from: defaults.data(forKey: "savedThemes")
        ) ?? []
    }

    func saveTheme(_ configuration: ThemeConfiguration) {
        let configuration = configuration.normalized
        guard configuration != theme else { return }

        theme = configuration
        savedThemes.removeAll { $0.configuration == configuration }
        savedThemes.insert(
            SavedTheme(id: UUID(), savedAt: Date(), configuration: configuration),
            at: 0
        )
        savedThemes = Array(savedThemes.prefix(maximumSavedThemes))

        if let data = try? encoder.encode(theme) {
            defaults.set(data, forKey: "themeConfiguration")
        }
        if let data = try? encoder.encode(savedThemes) {
            defaults.set(data, forKey: "savedThemes")
        }
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
