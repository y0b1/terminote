import Darwin
import Foundation

final class SingleInstance {
    static let activationNotification = Notification.Name("com.terminote.Terminote.activate")

    private var lockDescriptor: Int32 = -1

    func acquire() -> Bool {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = support.appendingPathComponent("Terminote", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        lockDescriptor = open(directory.appendingPathComponent("instance.lock").path, O_CREAT | O_RDWR, 0o600)
        guard lockDescriptor >= 0 else { return false }
        return flock(lockDescriptor, LOCK_EX | LOCK_NB) == 0
    }

    deinit {
        if lockDescriptor >= 0 {
            flock(lockDescriptor, LOCK_UN)
            close(lockDescriptor)
        }
    }
}
