import Combine
import Foundation

@MainActor
final class WorkspaceStore: ObservableObject {
    let note: NoteStore

    private let fileManager = FileManager.default
    private let directory: URL

    init() {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent("Terminote", isDirectory: true)

        Self.migrateLegacyDataIfNeeded(to: directory, using: fileManager)
        let historyDirectory = directory.appendingPathComponent("history", isDirectory: true)
        try? fileManager.createDirectory(at: historyDirectory, withIntermediateDirectories: true)

        note = NoteStore(
            id: UUID(uuidString: "5445524D-494E-4F54-4500-000000000001")!,
            noteURL: directory.appendingPathComponent("note.txt"),
            historyURL: historyDirectory,
            usesLegacySelection: true
        )
    }

    var containingFolder: URL { directory }

    func flush() {
        note.flush()
    }

    private static func migrateLegacyDataIfNeeded(to destination: URL, using fileManager: FileManager) {
        guard !fileManager.fileExists(atPath: destination.path) else { return }
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let legacy = support.appendingPathComponent("Scratch", isDirectory: true)
        guard fileManager.fileExists(atPath: legacy.path) else { return }

        do {
            try fileManager.copyItem(at: legacy, to: destination)
        } catch {
            NSLog("Terminote could not migrate Scratch data: %@", error.localizedDescription)
        }
    }
}
