import AppKit
import Foundation
import JsonLensCore

struct InputCandidate {
    let text: String
    let sourceKind: JSONSourceKind
    let description: String
}

enum ClipboardReader {
    static func candidates(
        pasteboard: NSPasteboard = .general,
        maxCharacters: Int,
        includeFileURLs: Bool
    ) -> [InputCandidate] {
        var results: [InputCandidate] = []

        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           text.count <= maxCharacters {
            results.append(InputCandidate(text: text, sourceKind: .clipboard, description: "Clipboard"))
        }

        guard includeFileURLs else {
            return results
        }

        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = pasteboard
            .readObjects(forClasses: [NSURL.self], options: options)?
            .compactMap { ($0 as? NSURL) as URL? } ?? []

        for url in urls.prefix(8) where supportedFileExtensions.contains(url.pathExtension.lowercased()) {
            guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  size <= maxCharacters * 4,
                  let text = try? String(contentsOf: url, encoding: .utf8),
                  text.count <= maxCharacters
            else {
                continue
            }
            results.append(InputCandidate(text: text, sourceKind: .file, description: url.lastPathComponent))
        }

        return results
    }

    private static let supportedFileExtensions: Set<String> = ["json", "jsonc", "jsonl", "har", "map"]
}
