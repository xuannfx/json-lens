import Foundation

public enum JSONSourceKind: String, Sendable {
    case selection = "Selection"
    case clipboard = "Clipboard"
    case file = "File"
    case manual = "Manual"
}

public enum JSONFormat: String, Sendable {
    case strictJSON = "JSON"
    case jsonc = "JSONC"
    case jsonLines = "JSON Lines"
    case urlEncodedJSON = "URL Encoded JSON"
    case base64JSON = "Base64 JSON"
    case embeddedJSON = "Embedded JSON"
}

public struct JSONTreeNode: Equatable, Sendable, Identifiable {
    public var id: String { path }

    public let path: String
    public let displayName: String
    public let depth: Int
    public let value: JSONValue
}

public struct JSONDocument: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let originalText: String
    public let normalizedText: String
    public let root: JSONValue
    public let format: JSONFormat
    public let sourceKind: JSONSourceKind
    public let sourceDescription: String
    public let notes: [String]

    public init(
        id: UUID = UUID(),
        originalText: String,
        normalizedText: String,
        root: JSONValue,
        format: JSONFormat,
        sourceKind: JSONSourceKind,
        sourceDescription: String,
        notes: [String] = []
    ) {
        self.id = id
        self.originalText = originalText
        self.normalizedText = normalizedText
        self.root = root
        self.format = format
        self.sourceKind = sourceKind
        self.sourceDescription = sourceDescription
        self.notes = notes
    }

    public var byteCount: Int {
        normalizedText.data(using: .utf8)?.count ?? normalizedText.utf8.count
    }

    public var nodeCount: Int {
        root.nodeCount
    }

    public var maxDepth: Int {
        root.maxDepth
    }

    public var topLevelSummary: String {
        root.shortDescription
    }

    public var prettyPrintedText: String {
        root.prettyPrinted()
    }

    public func flattenedNodes() -> [JSONTreeNode] {
        var result: [JSONTreeNode] = []
        appendNodes(value: root, displayName: "$", path: "$", depth: 0, into: &result)
        return result
    }

    public func value(at path: String) -> JSONValue? {
        root.value(at: path)
    }

    private func appendNodes(
        value: JSONValue,
        displayName: String,
        path: String,
        depth: Int,
        into result: inout [JSONTreeNode]
    ) {
        result.append(JSONTreeNode(path: path, displayName: displayName, depth: depth, value: value))

        switch value {
        case .object(let entries):
            for entry in entries {
                let childPath = path + JSONDocument.pathComponent(forKey: entry.key)
                appendNodes(value: entry.value, displayName: entry.key, path: childPath, depth: depth + 1, into: &result)
            }
        case .array(let values):
            for (index, child) in values.enumerated() {
                let childPath = "\(path)[\(index)]"
                appendNodes(value: child, displayName: "[\(index)]", path: childPath, depth: depth + 1, into: &result)
            }
        case .string, .number, .bool, .null:
            return
        }
    }

    private static func pathComponent(forKey key: String) -> String {
        let simpleKey = key.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
        if simpleKey {
            return ".\(key)"
        }

        let escaped = key
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "[\"\(escaped)\"]"
    }
}
