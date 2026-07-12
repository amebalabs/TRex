import Foundation

/// Output format for detected tables
public enum TableOutputFormat: String, CaseIterable, Sendable {
    case markdown = "Markdown"
    case csv = "CSV"
    case tsv = "TSV"
    case json = "JSON"
}

/// A detected table with optional headers and rows of cell values
public struct DetectedTable: Sendable {
    public let headers: [String]?
    public let rows: [[String]]

    public init(headers: [String]?, rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }

    /// Format the table as Markdown
    public func toMarkdown() -> String {
        var lines: [String] = []

        let columnCount = max(headers?.count ?? 0, rows.map(\.count).max() ?? 0)
        guard columnCount > 0 else { return "" }

        func markdownCell(_ value: String) -> String {
            value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "|", with: "\\|")
                .replacingOccurrences(of: "\r\n", with: "<br>")
                .replacingOccurrences(of: "\n", with: "<br>")
                .replacingOccurrences(of: "\r", with: "<br>")
        }

        func normalizedRow(_ values: [String]) -> [String] {
            (0..<columnCount).map { index in
                index < values.count ? markdownCell(values[index]) : ""
            }
        }

        // Calculate column widths
        var widths = Array(repeating: 3, count: columnCount)
        if let headers = headers {
            for (i, cell) in normalizedRow(headers).enumerated() {
                widths[i] = max(widths[i], cell.count)
            }
        }
        for row in rows {
            for (i, cell) in normalizedRow(row).enumerated() {
                widths[i] = max(widths[i], cell.count)
            }
        }

        // Header row (use empty headers when none are provided)
        let headerCells = normalizedRow(headers ?? [])
        let headerRow = headerCells.enumerated().map { i, cell in
            cell.padding(toLength: widths[i], withPad: " ", startingAt: 0)
        }
        lines.append("| " + headerRow.joined(separator: " | ") + " |")

        // Separator
        let separator = widths.map { String(repeating: "-", count: $0) }
        lines.append("| " + separator.joined(separator: " | ") + " |")

        // Data rows (skip first if it was the header)
        for row in rows {
            let cells = normalizedRow(row).enumerated().map { index, cell in
                cell.padding(toLength: widths[index], withPad: " ", startingAt: 0)
            }
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }

        return lines.joined(separator: "\n")
    }

    /// Format the table as CSV
    public func toCSV() -> String {
        var lines: [String] = []

        if let headers = headers {
            lines.append(headers.map { escapeCSVField($0) }.joined(separator: ","))
        }

        for row in rows {
            lines.append(row.map { escapeCSVField($0) }.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    /// Format the table as TSV
    public func toTSV() -> String {
        var lines: [String] = []

        if let headers = headers {
            lines.append(headers.map { escapeTSVField($0) }.joined(separator: "\t"))
        }

        for row in rows {
            lines.append(row.map { escapeTSVField($0) }.joined(separator: "\t"))
        }

        return lines.joined(separator: "\n")
    }

    /// Format the table as JSON
    public func toJSON() -> String {
        if let headers = headers {
            // Array of dictionaries keyed by header names
            let dicts: [[String: String]] = rows.map { row in
                var dict: [String: String] = [:]
                for (i, header) in headers.enumerated() {
                    dict[header] = i < row.count ? row[i] : ""
                }
                return dict
            }
            if let data = try? JSONSerialization.data(
                withJSONObject: dicts,
                options: [.prettyPrinted, .sortedKeys]
            ) {
                return String(data: data, encoding: .utf8) ?? "[]"
            }
            return "[]"
        } else {
            // Array of arrays
            if let data = try? JSONSerialization.data(
                withJSONObject: rows,
                options: [.prettyPrinted]
            ) {
                return String(data: data, encoding: .utf8) ?? "[]"
            }
            return "[]"
        }
    }

    /// Format the table in the specified output format
    public func formatted(as format: TableOutputFormat) -> String {
        switch format {
        case .markdown: return toMarkdown()
        case .csv: return toCSV()
        case .tsv: return toTSV()
        case .json: return toJSON()
        }
    }

    // MARK: - Private helpers

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private func escapeTSVField(_ field: String) -> String {
        return field
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}

/// Result from document recognition containing detected tables and plain text
public struct DocumentResult: Sendable {
    public let tables: [DetectedTable]
    public let plainText: String

    public init(tables: [DetectedTable], plainText: String) {
        self.tables = tables
        self.plainText = plainText
    }
}
