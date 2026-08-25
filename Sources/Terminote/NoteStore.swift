import AppKit
import Combine
import Foundation

@MainActor
final class NoteStore: ObservableObject, Identifiable {
    let id: UUID

    @Published var text: String {
        didSet {
            guard !isLoading else { return }
            scheduleSave()
        }
    }

    private(set) var selection: NSRange

    private let fileManager = FileManager.default
    private let noteURL: URL
    private let historyURL: URL
    private let defaults = UserDefaults.standard
    private var pendingSave: DispatchWorkItem?
    private var lastSavedText: String
    private var isLoading = true

    init(id: UUID, noteURL: URL, historyURL: URL, usesLegacySelection: Bool = false) {
        self.id = id
        self.noteURL = noteURL
        self.historyURL = historyURL

        try? fileManager.createDirectory(at: historyURL, withIntermediateDirectories: true)
        let loaded = (try? String(contentsOf: noteURL, encoding: .utf8)) ?? ""
        text = loaded
        lastSavedText = loaded

        let prefix = "selection.\(id.uuidString)"
        let hasStoredSelection = defaults.object(forKey: "\(prefix).location") != nil
        let locationKey = hasStoredSelection || !usesLegacySelection ? "\(prefix).location" : "selectionLocation"
        let lengthKey = hasStoredSelection || !usesLegacySelection ? "\(prefix).length" : "selectionLength"
        selection = NSRange(
            location: defaults.integer(forKey: locationKey),
            length: defaults.integer(forKey: lengthKey)
        )
        selection = clamped(selection, toUTF16Length: loaded.utf16.count)
        isLoading = false
    }

    func setSelection(_ range: NSRange) {
        selection = clamped(range, toUTF16Length: text.utf16.count)
        let prefix = "selection.\(id.uuidString)"
        defaults.set(selection.location, forKey: "\(prefix).location")
        defaults.set(selection.length, forKey: "\(prefix).length")
    }

    func flush() {
        pendingSave?.cancel()
        pendingSave = nil
        saveIfNeeded()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.saveIfNeeded()
            }
        }
        pendingSave = item
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: item)
    }

    private func saveIfNeeded() {
        guard text != lastSavedText else { return }
        let snapshot = text

        do {
            try fileManager.createDirectory(
                at: noteURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = Data(snapshot.utf8)

            // Data's atomic option writes a sibling temporary file, then replaces the note.
            try data.write(to: noteURL, options: .atomic)
            try data.write(to: nextHistoryURL(), options: .atomic)
            lastSavedText = snapshot
            pruneHistory()
        } catch {
            NSLog("Terminote could not save a note: %@", error.localizedDescription)
        }
    }

    private func nextHistoryURL() -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return historyURL.appendingPathComponent("\(stamp)-\(UUID().uuidString.prefix(8)).txt")
    }

    private func pruneHistory() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: historyURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let sorted = files.filter {
            $0.pathExtension == "txt"
                && ((try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) ?? false)
        }.sorted {
            let left = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let right = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return left > right
        }
        for file in sorted.dropFirst(20) {
            try? fileManager.removeItem(at: file)
        }
    }

    private func clamped(_ range: NSRange, toUTF16Length length: Int) -> NSRange {
        let location = min(max(0, range.location), length)
        let available = length - location
        return NSRange(location: location, length: min(max(0, range.length), available))
    }
}
