import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var showsLineNumbers: Bool {
        didSet { UserDefaults.standard.set(showsLineNumbers, forKey: "showsLineNumbers") }
    }

    init() {
        showsLineNumbers = UserDefaults.standard.bool(forKey: "showsLineNumbers")
    }
}
