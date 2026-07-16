import Foundation

public struct JSONDetectionOptions: Sendable {
    public var maxCharacters: Int
    public var requireContainerTopLevel: Bool

    public init(maxCharacters: Int = 200_000, requireContainerTopLevel: Bool = true) {
        self.maxCharacters = maxCharacters
        self.requireContainerTopLevel = requireContainerTopLevel
    }

    public static let `default` = JSONDetectionOptions()
}

public enum JSONDetector {
    public static func detect(
        _ text: String,
        sourceKind: JSONSourceKind = .selection,
        sourceDescription: String? = nil,
        options: JSONDetectionOptions = .default
    ) -> JSONDocument? {
        let original = text
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, trimmed.count <= options.maxCharacters else {
            return nil
        }

        let source = sourceDescription ?? sourceKind.rawValue

        for candidate in candidates(from: trimmed) {
            if let document = parseCandidate(
                candidate.text,
                originalText: original,
                format: candidate.format,
                sourceKind: sourceKind,
                sourceDescription: source,
                notes: candidate.notes,
                options: options
            ) {
                return document
            }

            if let jsonLines = parseJSONLines(
                candidate.text,
                originalText: original,
                sourceKind: sourceKind,
                sourceDescription: source,
                options: options
            ) {
                return jsonLines
            }
        }

        if let jsonLines = parseJSONLines(
            trimmed,
            originalText: original,
            sourceKind: sourceKind,
            sourceDescription: source,
            options: options
        ) {
            return jsonLines
        }

        if let embedded = extractBalancedJSONSubstring(from: trimmed), embedded != trimmed {
            return parseCandidate(
                embedded,
                originalText: original,
                format: .embeddedJSON,
                sourceKind: sourceKind,
                sourceDescription: source,
                notes: ["Extracted the first balanced JSON object or array."],
                options: options
            )
        }

        return nil
    }

    private struct Candidate {
        let text: String
        let format: JSONFormat
        let notes: [String]
    }

    private static func candidates(from text: String) -> [Candidate] {
        var candidates: [Candidate] = [
            Candidate(text: text, format: .strictJSON, notes: [])
        ]

        if let fenced = extractFirstJSONCodeFence(from: text) {
            candidates.append(Candidate(text: fenced, format: .embeddedJSON, notes: ["Extracted from Markdown code fence."]))
        }

        if let decoded = text.removingPercentEncoding, decoded != text {
            candidates.append(Candidate(text: decoded.trimmingCharacters(in: .whitespacesAndNewlines), format: .urlEncodedJSON, notes: ["Decoded percent-encoded text."]))
        }

        if let decoded = decodeBase64JSONCandidate(text) {
            candidates.append(Candidate(text: decoded, format: .base64JSON, notes: ["Decoded Base64 text before parsing."]))
        }

        let jsonc = removeTrailingCommas(normalizeLooseJSONPunctuation(stripJSONComments(text)))
        if jsonc != text {
            candidates.append(Candidate(text: jsonc, format: .jsonc, notes: ["Removed comments, normalized loose punctuation, or trailing commas before parsing."]))
        }

        return candidates
    }

    private static func parseCandidate(
        _ text: String,
        originalText: String,
        format: JSONFormat,
        sourceKind: JSONSourceKind,
        sourceDescription: String,
        notes: [String],
        options: JSONDetectionOptions
    ) -> JSONDocument? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard looksLikeJSONContainer(normalized) || !options.requireContainerTopLevel else {
            return nil
        }

        guard let root = parseJSONValue(normalized) else {
            return nil
        }

        if options.requireContainerTopLevel {
            switch root {
            case .object, .array:
                break
            case .string, .number, .bool, .null:
                return nil
            }
        }

        return JSONDocument(
            originalText: originalText,
            normalizedText: normalized,
            root: root,
            format: format,
            sourceKind: sourceKind,
            sourceDescription: sourceDescription,
            notes: notes
        )
    }

    private static func parseJSONLines(
        _ text: String,
        originalText: String,
        sourceKind: JSONSourceKind,
        sourceDescription: String,
        options: JSONDetectionOptions
    ) -> JSONDocument? {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count > 1, lines.count <= 5_000 else {
            return nil
        }

        var values: [JSONValue] = []
        values.reserveCapacity(lines.count)

        for line in lines {
            guard line.count <= options.maxCharacters, let value = parseJSONValue(line) else {
                return nil
            }
            values.append(value)
        }

        return JSONDocument(
            originalText: originalText,
            normalizedText: "[\n" + lines.joined(separator: ",\n") + "\n]",
            root: .array(values),
            format: .jsonLines,
            sourceKind: sourceKind,
            sourceDescription: sourceDescription,
            notes: ["Parsed each non-empty line as one JSON value."]
        )
    }

    private static func parseJSONValue(_ text: String) -> JSONValue? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return JSONValue.fromJSONCompatible(object)
        } catch {
            return nil
        }
    }

    private static func looksLikeJSONContainer(_ text: String) -> Bool {
        guard let first = text.first, let last = text.last else {
            return false
        }
        return (first == "{" && last == "}") || (first == "[" && last == "]")
    }

    private static func extractFirstJSONCodeFence(from text: String) -> String? {
        guard let startRange = text.range(of: "```") else {
            return nil
        }

        let afterFence = text[startRange.upperBound...]
        guard let firstLineEnd = afterFence.firstIndex(where: \.isNewline) else {
            return nil
        }

        let language = afterFence[..<firstLineEnd].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard language.isEmpty || language.contains("json") else {
            return nil
        }

        let contentStart = afterFence.index(after: firstLineEnd)
        guard let endRange = afterFence[contentStart...].range(of: "```") else {
            return nil
        }

        return String(afterFence[contentStart..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeBase64JSONCandidate(_ text: String) -> String? {
        let compact = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        guard compact.count >= 12,
              compact.range(of: #"^[A-Za-z0-9+/=_-]+$"#, options: .regularExpression) != nil
        else {
            return nil
        }

        let normalized = compact
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .padding(toLength: compact.count + (4 - compact.count % 4) % 4, withPad: "=", startingAt: 0)

        guard let data = Data(base64Encoded: normalized),
              let decoded = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
        return looksLikeJSONContainer(trimmed) ? trimmed : nil
    }

    private static func stripJSONComments(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        var inString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)

            if inString {
                result.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                index = next
                continue
            }

            if character == "\"" {
                inString = true
                result.append(character)
                index = next
                continue
            }

            if character == "/", next < text.endIndex {
                let nextCharacter = text[next]
                if nextCharacter == "/" {
                    index = text.index(after: next)
                    while index < text.endIndex, !text[index].isNewline {
                        index = text.index(after: index)
                    }
                    result.append("\n")
                    continue
                }

                if nextCharacter == "*" {
                    index = text.index(after: next)
                    while index < text.endIndex {
                        let closeNext = text.index(after: index)
                        if text[index] == "*", closeNext < text.endIndex, text[closeNext] == "/" {
                            index = text.index(after: closeNext)
                            break
                        }
                        result.append(text[index].isNewline ? "\n" : " ")
                        index = closeNext
                    }
                    continue
                }
            }

            result.append(character)
            index = next
        }

        return result
    }

    private static func removeTrailingCommas(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        var inString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]

            if inString {
                result.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                index = text.index(after: index)
                continue
            }

            if character == "\"" {
                inString = true
                result.append(character)
                index = text.index(after: index)
                continue
            }

            if character == "," {
                var lookahead = text.index(after: index)
                while lookahead < text.endIndex, text[lookahead].isWhitespace {
                    lookahead = text.index(after: lookahead)
                }
                if lookahead < text.endIndex, text[lookahead] == "}" || text[lookahead] == "]" {
                    index = text.index(after: index)
                    continue
                }
            }

            result.append(character)
            index = text.index(after: index)
        }

        return result
    }

    private static func normalizeLooseJSONPunctuation(_ text: String) -> String {
        var result = ""
        var index = text.startIndex
        var inString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]

            if inString {
                result.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                index = text.index(after: index)
                continue
            }

            if character == "\"" {
                inString = true
                result.append(character)
                index = text.index(after: index)
                continue
            }

            switch character {
            case "，":
                result.append(",")
            case "：":
                result.append(":")
            default:
                result.append(character)
            }
            index = text.index(after: index)
        }

        return result
    }

    private static func extractBalancedJSONSubstring(from text: String) -> String? {
        guard let start = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else {
            return nil
        }

        let opening = text[start]
        let closing: Character = opening == "{" ? "}" : "]"
        var depth = 0
        var index = start
        var inString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]

            if inString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                index = text.index(after: index)
                continue
            }

            if character == "\"" {
                inString = true
            } else if character == opening {
                depth += 1
            } else if character == closing {
                depth -= 1
                if depth == 0 {
                    let end = text.index(after: index)
                    return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            index = text.index(after: index)
        }

        return nil
    }
}
