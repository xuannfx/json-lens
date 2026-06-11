import Foundation

public struct JSONObjectEntry: Equatable, Sendable, Identifiable {
    public var id: String { key }

    public let key: String
    public let value: JSONValue

    public init(key: String, value: JSONValue) {
        self.key = key
        self.value = value
    }
}

public enum JSONValue: Equatable, Sendable {
    case object([JSONObjectEntry])
    case array([JSONValue])
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    public var typeName: String {
        switch self {
        case .object:
            return "Object"
        case .array:
            return "Array"
        case .string:
            return "String"
        case .number:
            return "Number"
        case .bool:
            return "Boolean"
        case .null:
            return "Null"
        }
    }

    public var childCount: Int {
        switch self {
        case .object(let entries):
            return entries.count
        case .array(let values):
            return values.count
        case .string, .number, .bool, .null:
            return 0
        }
    }

    public var isContainer: Bool {
        childCount > 0
    }

    public var shortDescription: String {
        switch self {
        case .object(let entries):
            return "\(entries.count) \(entries.count == 1 ? "key" : "keys")"
        case .array(let values):
            return "\(values.count) \(values.count == 1 ? "item" : "items")"
        case .string(let value):
            return "\"\(value.truncatedForDisplay(limit: 80))\""
        case .number(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }

    public var scalarText: String {
        switch self {
        case .object, .array:
            return prettyPrinted()
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }

    public var nodeCount: Int {
        switch self {
        case .object(let entries):
            return 1 + entries.reduce(0) { $0 + $1.value.nodeCount }
        case .array(let values):
            return 1 + values.reduce(0) { $0 + $1.nodeCount }
        case .string, .number, .bool, .null:
            return 1
        }
    }

    public var maxDepth: Int {
        switch self {
        case .object(let entries):
            return 1 + (entries.map(\.value.maxDepth).max() ?? 0)
        case .array(let values):
            return 1 + (values.map(\.maxDepth).max() ?? 0)
        case .string, .number, .bool, .null:
            return 1
        }
    }

    public var objectEntries: [JSONObjectEntry]? {
        if case .object(let entries) = self {
            return entries
        }
        return nil
    }

    public var arrayValues: [JSONValue]? {
        if case .array(let values) = self {
            return values
        }
        return nil
    }

    public static func fromJSONCompatible(_ value: Any) -> JSONValue {
        if value is NSNull {
            return .null
        }

        if let string = value as? String {
            return .string(string)
        }

        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.description(withLocale: Locale(identifier: "en_US_POSIX")))
        }

        if let array = value as? [Any] {
            return .array(array.map(JSONValue.fromJSONCompatible))
        }

        if let dictionary = value as? NSDictionary {
            let entries = dictionary.allKeys
                .compactMap { $0 as? String }
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                .map { key in
                    JSONObjectEntry(key: key, value: JSONValue.fromJSONCompatible(dictionary[key] ?? NSNull()))
                }
            return .object(entries)
        }

        return .string(String(describing: value))
    }

    public func jsonCompatibleObject() -> Any {
        switch self {
        case .object(let entries):
            var result: [String: Any] = [:]
            for entry in entries {
                result[entry.key] = entry.value.jsonCompatibleObject()
            }
            return result
        case .array(let values):
            return values.map { $0.jsonCompatibleObject() }
        case .string(let value):
            return value
        case .number(let value):
            if let integer = Int64(value) {
                return integer
            }
            if let double = Double(value) {
                return double
            }
            return value
        case .bool(let value):
            return value
        case .null:
            return NSNull()
        }
    }

    public func prettyPrinted() -> String {
        let object = jsonCompatibleObject()
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .withoutEscapingSlashes]
              ),
              let text = String(data: data, encoding: .utf8)
        else {
            return shortDescription
        }
        return text
    }

    public func value(at path: String) -> JSONValue? {
        guard path != "$" else {
            return self
        }

        var current = self
        var cursor = path.dropFirst()

        while !cursor.isEmpty {
            if cursor.first == "." {
                cursor = cursor.dropFirst()
                let key = String(cursor.prefix { $0 != "." && $0 != "[" })
                guard !key.isEmpty, let entries = current.objectEntries,
                      let next = entries.first(where: { $0.key == key })?.value
                else {
                    return nil
                }
                current = next
                cursor = cursor.dropFirst(key.count)
                continue
            }

            if cursor.first == "[" {
                guard let close = cursor.firstIndex(of: "]") else {
                    return nil
                }
                let token = String(cursor[cursor.index(after: cursor.startIndex)..<close])
                if token.hasPrefix("\""), token.hasSuffix("\"") {
                    let key = String(token.dropFirst().dropLast())
                        .replacingOccurrences(of: "\\\"", with: "\"")
                        .replacingOccurrences(of: "\\\\", with: "\\")
                    guard let entries = current.objectEntries,
                          let next = entries.first(where: { $0.key == key })?.value
                    else {
                        return nil
                    }
                    current = next
                } else if let index = Int(token) {
                    guard let values = current.arrayValues, values.indices.contains(index) else {
                        return nil
                    }
                    current = values[index]
                } else {
                    return nil
                }
                cursor = cursor[cursor.index(after: close)...]
                continue
            }

            return nil
        }

        return current
    }
}

public extension String {
    func truncatedForDisplay(limit: Int) -> String {
        guard count > limit else {
            return self
        }
        let end = index(startIndex, offsetBy: max(0, limit - 1))
        return String(self[..<end]) + "..."
    }
}
