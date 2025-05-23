import Foundation
import Sentry

/**
 * Stores the DSN to a file in the cache directory.
 */
public class DSNStorage {
    public static let shared = DSNStorage()
    private let dsnFile: URL

    private init() {
        // swiftlint:disable force_unwrapping
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        // swiftlint:enable force_unwrapping
        dsnFile = cachesDirectory.appendingPathComponent("dsn")
    }

    public func saveDSN(dsn: String) throws {
        try deleteDSN()
        try dsn.write(to: dsnFile, atomically: true, encoding: .utf8)
    }

    public func getDSN() throws -> String? {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: dsnFile.path) else {
            return nil
        }

        return try String(contentsOfFile: dsnFile.path)
    }

    public func deleteDSN() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: dsnFile.path) {
            try fileManager.removeItem(at: dsnFile)
        }
    }
}
