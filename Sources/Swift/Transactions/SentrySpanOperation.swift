import Foundation

/**
 * Span operations are short string identifiers that categorize the type of operation a span is measuring.
 *
 * They follow a hierarchical dot notation format (e.g. 'ui.load.initial_display') to group related operations.
 * These identifiers help organize and analyze performance data across different types of operations.
 *
 * See [Sentry SDK development documentation](https://develop.sentry.dev/sdk/telemetry/traces/span-operations/) for more information.
 */
@objcMembers @objc(SentrySpanOperation)
class SentrySpanOperation: NSObject {
    static let appLifecycle = "app.lifecycle"

    static let coredataFetchOperation = "db.sql.query"
    static let coredataSaveOperation = "db.sql.transaction"

    static let fileRead = "file.read"
    static let fileWrite = "file.write"
    static let fileCopy = "file.copy"
    static let fileRename = "file.rename"
    static let fileDelete = "file.delete"

    static let networkRequestOperation = "http.client"

    static let uiAction = "ui.action"
    static let uiActionClick = "ui.action.click"

    static let uiLoad = "ui.load"
    static let uiLoadInitialDisplay = "ui.load.initial_display"
    static let uiLoadFullDisplay = "ui.load.full_display"
}
