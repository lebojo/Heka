import Foundation
import SQLite3

/// A short-lived, read-only snapshot of an agent's database, including its WAL.
final class SessionDatabase {
    private var connection: OpaquePointer?

    init?(_ url: URL) {
        guard sqlite3_open_v2(url.path, &connection, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(connection)
            connection = nil
            return nil
        }
        sqlite3_busy_timeout(connection, 100)
        sqlite3_exec(connection, "BEGIN", nil, nil, nil)
    }

    deinit { sqlite3_close(connection) }

    func rows(_ query: String, bindings: [String] = []) -> [[String: String]]? {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(connection, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        for (index, value) in bindings.enumerated() {
            _ = value.withCString { sqlite3_bind_text(statement, Int32(index + 1), $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
        }
        var result: [[String: String]] = []
        var status = sqlite3_step(statement)
        while status == SQLITE_ROW {
            var row: [String: String] = [:]
            for column in 0..<sqlite3_column_count(statement) {
                guard let value = sqlite3_column_text(statement, column) else { continue }
                row[String(cString: sqlite3_column_name(statement, column))] = String(cString: value)
            }
            result.append(row)
            status = sqlite3_step(statement)
        }
        return status == SQLITE_DONE ? result : nil
    }
}
