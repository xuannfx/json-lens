import Foundation
import JsonLensCore

enum ViewerMode: String, CaseIterable, Identifiable {
    case tree = "Tree"
    case raw = "Raw"
    case columns = "Columns"

    var id: String { rawValue }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var document: JSONDocument?
    @Published var selectedPath = "$"
    @Published var searchText = ""
    @Published var mode: ViewerMode = .tree
    @Published var rawWrap = true
    @Published var expandedPaths: Set<String> = ["$"]
    @Published var statusText: String?

    func show(_ document: JSONDocument) {
        self.document = document
        selectedPath = "$"
        searchText = ""
        mode = .tree
        expandedPaths = ["$"]
        statusText = nil
    }

    func select(_ path: String) {
        selectedPath = path
        expandAncestors(of: path)
    }

    func selectedValue() -> JSONValue? {
        document?.value(at: selectedPath)
    }

    func isExpanded(_ path: String) -> Bool {
        expandedPaths.contains(path)
    }

    func setExpanded(_ isExpanded: Bool, path: String) {
        if isExpanded {
            expandedPaths.insert(path)
        } else {
            expandedPaths.remove(path)
        }
    }

    func expandAll() {
        guard let document else { return }
        expandedPaths = Set(document.flattenedNodes().filter { $0.value.isContainer }.map(\.path))
    }

    func collapseAll() {
        expandedPaths = ["$"]
    }

    func searchResults() -> [JSONTreeNode] {
        guard let document else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        return document.flattenedNodes().filter {
            $0.path.localizedCaseInsensitiveContains(query)
                || $0.displayName.localizedCaseInsensitiveContains(query)
                || $0.value.scalarText.localizedCaseInsensitiveContains(query)
        }
    }

    private func expandAncestors(of path: String) {
        guard let document else { return }
        for node in document.flattenedNodes() where node.value.isContainer && isAncestor(node.path, of: path) {
            expandedPaths.insert(node.path)
        }
    }
}
