import AppKit
import JsonLensCore
import SwiftUI

struct JsonPopupView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var settings: SettingsStore

    var body: some View {
        let palette = settings.colorTheme.palette

        Group {
            if let document = model.document {
                VStack(spacing: 0) {
                    HeaderView(document: document, model: model)
                    Divider()
                    ToolbarView(document: document, model: model)
                    Divider()
                    HSplitView {
                        MainBrowserView(document: document, model: model)
                            .frame(minWidth: 380, idealWidth: 680, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                        InspectorView(document: document, model: model)
                            .frame(minWidth: 240, idealWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(0)
                    }
                    .frame(minWidth: 680, maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                EmptyPopupView(message: model.statusText ?? "Copy JSON or open clipboard")
            }
        }
        .environment(\.lensPalette, palette)
        .background(palette.window.color)
        .preferredColorScheme(settings.appearance.colorScheme)
        .id("\(settings.colorTheme.rawValue)-\(settings.appearance.rawValue)")
    }
}

private struct HeaderView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(typeColor(document.root, palette: palette).opacity(0.13))
                Image(systemName: "curlybraces.square.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(typeColor(document.root, palette: palette))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(document.sourceDescription)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Badge(text: document.format.rawValue, color: typeColor(document.root, palette: palette))
                    Badge(text: document.sourceKind.rawValue, color: .secondary)
                }

                HStack(spacing: 12) {
                    Metric(systemImage: "point.3.connected.trianglepath.dotted", text: "\(document.nodeCount) nodes")
                    Metric(systemImage: "arrow.down.right.and.arrow.up.left", text: "depth \(document.maxDepth)")
                    Metric(systemImage: "doc", text: byteText(document.byteCount))
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            IconButton(title: "Copy JSON", systemImage: "doc.on.doc") {
                copyToPasteboard(document.prettyPrintedText)
                model.statusText = "Copied JSON"
            }

            IconButton(title: "Copy Path", systemImage: "point.topleft.down.curvedto.point.bottomright.up") {
                copyToPasteboard(model.selectedPath)
                model.statusText = "Copied path"
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

private struct ToolbarView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            Picker("", selection: $model.mode) {
                ForEach(ViewerMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search keys, paths, values", text: $model.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(palette.code.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(palette.border.color)
            )

            Spacer()

            if model.mode == .tree {
                Button {
                    model.expandAll()
                } label: {
                    Label("Expand", systemImage: "arrow.down.right.and.arrow.up.left")
                }
                .controlSize(.small)

                Button {
                    model.collapseAll()
                } label: {
                    Label("Collapse", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .controlSize(.small)
            }

            if model.mode == .raw {
                RawColorLegend()
                    .layoutPriority(2)

                Toggle(isOn: $model.rawWrap) {
                    Label("Wrap", systemImage: "text.alignleft")
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(palette.window.color)
    }
}

private struct RawColorLegend: View {
    @Environment(\.lensPalette) private var palette

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) {
                LegendChip(label: "Key", color: CodeTokenKind.key.color(in: palette))
                LegendChip(label: "Str", color: CodeTokenKind.string.color(in: palette))
                LegendChip(label: "Num", color: CodeTokenKind.number.color(in: palette))
                LegendChip(label: "Bool", color: CodeTokenKind.bool.color(in: palette))
                LegendChip(label: "Null", color: CodeTokenKind.null.color(in: palette))
            }
            .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: 6) {
                LegendDot(label: "Key", color: CodeTokenKind.key.color(in: palette))
                LegendDot(label: "String", color: CodeTokenKind.string.color(in: palette))
                LegendDot(label: "Number", color: CodeTokenKind.number.color(in: palette))
                LegendDot(label: "Boolean", color: CodeTokenKind.bool.color(in: palette))
                LegendDot(label: "Null", color: CodeTokenKind.null.color(in: palette))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Raw JSON color legend")
    }
}

private struct LegendChip: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct LegendDot: View {
    let label: String
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .help(label)
    }
}

private struct MainBrowserView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if !model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                SearchResultsView(model: model)
            } else {
                switch model.mode {
                case .columns:
                    ColumnBrowserView(document: document, model: model)
                case .tree:
                    TreeBrowserView(document: document, model: model)
                case .raw:
                    RawBrowserView(document: document, model: model, wrap: model.rawWrap)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ColumnBrowserView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        let columns = columnContexts(document: document, selectedPath: model.selectedPath)

        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(columns) { column in
                    ColumnListView(column: column, model: model)
                        .frame(width: 280)
                    Divider()
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .background(palette.pane.color)
    }
}

private struct ColumnListView: View {
    let column: ColumnContext
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(column.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("\(column.children.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(palette.window.color)

            Divider()

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(column.children) { child in
                        ColumnRow(child: child, isSelected: child.path == column.selectedChildPath) {
                            model.select(child.path)
                        }
                    }
                }
                .padding(6)
            }
        }
    }
}

private struct ColumnRow: View {
    let child: JSONChild
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.lensPalette) private var palette

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ValueIcon(value: child.value)
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                    Text(child.value.shortDescription)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if child.value.isContainer {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? palette.selected.color : .clear)
        )
    }
}

private struct TreeBrowserView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                TreeNodeView(name: "$", path: "$", value: document.root, depth: 0, model: model)
            }
            .padding(10)
        }
        .background(palette.pane.color)
    }
}

private struct TreeNodeView: View {
    let name: String
    let path: String
    let value: JSONValue
    let depth: Int
    @ObservedObject var model: AppModel

    var body: some View {
        if value.isContainer {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { model.isExpanded(path) },
                    set: { model.setExpanded($0, path: path) }
                )
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(childNodes(for: value, parentPath: path)) { child in
                        TreeNodeView(
                            name: child.name,
                            path: child.path,
                            value: child.value,
                            depth: depth + 1,
                            model: model
                        )
                    }
                }
            } label: {
                TreeRow(name: name, path: path, value: value, depth: depth, model: model)
            }
        } else {
            TreeRow(name: name, path: path, value: value, depth: depth, model: model)
        }
    }
}

private struct TreeRow: View {
    let name: String
    let path: String
    let value: JSONValue
    let depth: Int
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        Button {
            model.select(path)
        } label: {
            HStack(alignment: .top, spacing: 8) {
                ValueIcon(value: value)
                    .padding(.top, 1)
                Text(name)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(minWidth: 48, idealWidth: 120, maxWidth: 180, alignment: .leading)
                Text(value.shortDescription)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if value.childCount > 0 {
                    Text("\(value.childCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, CGFloat(depth) * 10)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(model.selectedPath == path ? palette.selected.color : .clear)
        )
    }
}

private struct RawBrowserView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    let wrap: Bool
    @Environment(\.lensPalette) private var palette

    private var lines: [RawLine] {
        rawLines(for: document)
    }

    var body: some View {
        Group {
            if wrap {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        RawCodeLines(
                            lines: lines,
                            selectedPath: model.selectedPath,
                            wrap: true,
                            select: model.select
                        )
                            .frame(width: max(proxy.size.width, 520), alignment: .leading)
                    }
                }
            } else {
                ScrollView([.vertical, .horizontal]) {
                    RawCodeLines(
                        lines: lines,
                        selectedPath: model.selectedPath,
                        wrap: false,
                        select: model.select
                    )
                        .frame(minWidth: 720, alignment: .leading)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.code.color)
    }
}

private struct RawCodeLines: View {
    let lines: [RawLine]
    let selectedPath: String
    let wrap: Bool
    let select: (String) -> Void

    private var gutterWidth: CGFloat {
        CGFloat(max(2, String(lines.count).count) * 8 + 18)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(lines) { line in
                RawCodeLine(
                    line: line,
                    gutterWidth: gutterWidth,
                    wrap: wrap,
                    isSelected: line.path == selectedPath,
                    isAlternate: (line.number - 1).isMultiple(of: 2),
                    select: select
                )
            }
        }
        .padding(.vertical, 10)
    }
}

private struct RawCodeLine: View {
    let line: RawLine
    let gutterWidth: CGFloat
    let wrap: Bool
    let isSelected: Bool
    let isAlternate: Bool
    let select: (String) -> Void
    @Environment(\.lensPalette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(line.number)")
                .font(.system(size: 11, design: .monospaced))
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? CodeTokenKind.key.color(in: palette) : Color(nsColor: .tertiaryLabelColor))
                .frame(width: gutterWidth, alignment: .trailing)
                .padding(.trailing, 10)
                .padding(.vertical, 2)
                .background(palette.gutter.color)

            Rectangle()
                .fill(isSelected ? CodeTokenKind.key.color(in: palette) : Color.clear)
                .frame(width: 3)

            highlightedText(line.text, palette: palette)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(wrap ? nil : 1)
                .fixedSize(horizontal: !wrap, vertical: true)
                .frame(maxWidth: wrap ? .infinity : nil, alignment: .leading)
                .padding(.leading, 10)
                .padding(.trailing, 16)
                .padding(.vertical, 2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let path = line.path {
                select(path)
            }
        }
        .background(isSelected ? palette.codeSelected.color : (isAlternate ? Color.clear : palette.hover.color))
    }
}

private struct SearchResultsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        let results = model.searchResults()

        ScrollView {
            LazyVStack(spacing: 3) {
                ForEach(results) { node in
                    Button {
                        model.select(node.path)
                    } label: {
                        HStack(spacing: 10) {
                            ValueIcon(value: node.value)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.path)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .lineLimit(1)
                                Text(node.value.shortDescription)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Badge(text: node.value.typeName, color: typeColor(node.value, palette: palette))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(model.selectedPath == node.path ? palette.selected.color : .clear)
                    )
                }
            }
            .padding(10)
        }
        .overlay {
            if results.isEmpty {
                Label("No matches", systemImage: "magnifyingglass")
                    .foregroundStyle(.secondary)
            }
        }
        .background(palette.pane.color)
    }
}

private struct InspectorView: View {
    let document: JSONDocument
    @ObservedObject var model: AppModel
    @Environment(\.lensPalette) private var palette

    var body: some View {
        let value = model.selectedValue() ?? document.root
        let insights = ValueInsight.detect(value)
        let children = childNodes(for: value, parentPath: model.selectedPath)
        let parentPath = parentJSONPath(model.selectedPath)

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button {
                            if let parentPath {
                                model.select(parentPath)
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(parentPath == nil)
                        .help("Back to parent")

                        Badge(text: value.typeName, color: typeColor(value, palette: palette))
                        Spacer()
                        Button {
                            copyToPasteboard(value.scalarText)
                            model.statusText = "Copied value"
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy value")
                    }

                    BreadcrumbView(path: model.selectedPath, select: model.select)

                    Text(model.selectedPath)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    InspectorMetric(title: "Preview", value: value.shortDescription)
                    InspectorMetric(title: "Children", value: "\(value.childCount)")

                    if !insights.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Detected")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(insights) { insight in
                                InsightRow(insight: insight)
                            }
                        }
                    }

                    if let status = model.statusText {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)

                if !children.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Children")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)

                        LazyVStack(spacing: 1) {
                            ForEach(Array(children.prefix(160))) { child in
                                Button {
                                    model.select(child.path)
                                } label: {
                                    HStack(spacing: 7) {
                                        ValueIcon(value: child.value)
                                        Text(child.name)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            if children.count > 160 {
                                Text("\(children.count - 160) more children")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.window.color)
    }
}

private struct EmptyPopupView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "curlybraces.square")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Json Lens")
                .font(.title3.weight(.semibold))
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(width: 540, height: 340)
    }
}

private struct BreadcrumbView: View {
    let path: String
    let select: (String) -> Void
    @Environment(\.lensPalette) private var palette

    var body: some View {
        let crumbs = breadcrumbItems(for: path)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(crumbs.enumerated()), id: \.element.path) { index, crumb in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }

                    Button {
                        select(crumb.path)
                    } label: {
                        Text(crumb.label)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(index == crumbs.count - 1 ? palette.selected.color : palette.pane.color)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(Capsule().fill(color.opacity(0.13)))
    }
}

private struct Metric: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption)
        .lineLimit(1)
    }
}

private struct IconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .controlSize(.small)
        .help(title)
    }
}

private struct ValueIcon: View {
    let value: JSONValue
    @Environment(\.lensPalette) private var palette

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(typeColor(value, palette: palette))
            .frame(width: 16)
    }

    private var icon: String {
        switch value {
        case .object:
            return "curlybraces"
        case .array:
            return "list.bullet"
        case .string:
            return "text.quote"
        case .number:
            return "number"
        case .bool:
            return "switch.2"
        case .null:
            return "minus.circle"
        }
    }
}

private struct InspectorMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(3)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InsightRow: View {
    let insight: ValueInsight
    @Environment(\.lensPalette) private var palette

    var body: some View {
        HStack(spacing: 7) {
            if let color = insight.color {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(palette.border.color))
            } else {
                Image(systemName: insight.systemImage)
                    .frame(width: 16)
            }
            Text(insight.text)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ColumnContext: Identifiable {
    let id: String
    let title: String
    let children: [JSONChild]
    let selectedChildPath: String?
}

private struct JSONChild: Identifiable {
    var id: String { path }

    let name: String
    let path: String
    let value: JSONValue
}

private struct RawLine: Identifiable {
    var id: Int { number }

    let number: Int
    let text: String
    let path: String?
}

private struct BreadcrumbItem {
    let label: String
    let path: String
}

private struct ValueInsight: Identifiable {
    let id = UUID()
    let systemImage: String
    let text: String
    let color: Color?

    static func detect(_ value: JSONValue) -> [ValueInsight] {
        guard case .string(let raw) = value else { return [] }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var results: [ValueInsight] = []

        if let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            results.append(ValueInsight(systemImage: "link", text: url.host ?? text, color: nil))
        }

        if ISO8601DateFormatter().date(from: text) != nil {
            results.append(ValueInsight(systemImage: "calendar", text: "ISO date", color: nil))
        }

        if let color = Color(hexString: text) {
            results.append(ValueInsight(systemImage: "paintpalette", text: text, color: color))
        }

        if JSONDetector.detect(text, sourceKind: .manual) != nil {
            results.append(ValueInsight(systemImage: "curlybraces.square", text: "JSON string", color: nil))
        }

        return results
    }
}

private struct CodeToken {
    let text: String
    let kind: CodeTokenKind
}

private enum CodeTokenKind {
    case plain
    case key
    case string
    case number
    case bool
    case null
    case punctuation

    func color(in palette: LensPalette) -> Color {
        switch self {
        case .plain:
            return palette.plain.color
        case .key:
            return palette.key.color
        case .string:
            return palette.string.color
        case .number:
            return palette.number.color
        case .bool:
            return palette.bool.color
        case .null:
            return palette.null.color
        case .punctuation:
            return palette.punctuation.color
        }
    }

    var weight: Font.Weight {
        switch self {
        case .key, .bool, .null:
            return .semibold
        case .number:
            return .medium
        case .plain, .string, .punctuation:
            return .regular
        }
    }
}

private func highlightedText(_ line: String, palette: LensPalette) -> Text {
    jsonHighlightedTokens(line).reduce(Text("")) { result, token in
        result + Text(token.text)
            .foregroundColor(token.kind.color(in: palette))
            .fontWeight(token.kind.weight)
    }
}

private func jsonHighlightedTokens(_ line: String) -> [CodeToken] {
    var tokens: [CodeToken] = []
    var cursor = line.startIndex
    var outsideStart = cursor

    func flushOutside(until end: String.Index) {
        guard outsideStart < end else { return }
        tokens.append(contentsOf: tokenizeOutsideJSON(String(line[outsideStart..<end])))
    }

    while cursor < line.endIndex {
        guard line[cursor] == "\"" else {
            cursor = line.index(after: cursor)
            continue
        }

        flushOutside(until: cursor)

        let stringStart = cursor
        cursor = line.index(after: cursor)
        var escaped = false

        while cursor < line.endIndex {
            let character = line[cursor]
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                cursor = line.index(after: cursor)
                break
            }
            if cursor < line.endIndex {
                cursor = line.index(after: cursor)
            }
        }

        let stringText = String(line[stringStart..<cursor])
        tokens.append(CodeToken(text: stringText, kind: isKeyString(in: line, after: cursor) ? .key : .string))
        outsideStart = cursor
    }

    flushOutside(until: line.endIndex)
    return tokens
}

private func tokenizeOutsideJSON(_ text: String) -> [CodeToken] {
    guard let regex = try? NSRegularExpression(
        pattern: #"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|\btrue\b|\bfalse\b|\bnull\b|[{}\[\]:,]"#
    ) else {
        return [CodeToken(text: text, kind: .plain)]
    }

    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)
    let matches = regex.matches(in: text, range: fullRange)
    var tokens: [CodeToken] = []
    var cursor = 0

    for match in matches {
        if match.range.location > cursor {
            let range = NSRange(location: cursor, length: match.range.location - cursor)
            tokens.append(CodeToken(text: nsText.substring(with: range), kind: .plain))
        }

        let value = nsText.substring(with: match.range)
        tokens.append(CodeToken(text: value, kind: kindForOutsideToken(value)))
        cursor = match.range.location + match.range.length
    }

    if cursor < nsText.length {
        let range = NSRange(location: cursor, length: nsText.length - cursor)
        tokens.append(CodeToken(text: nsText.substring(with: range), kind: .plain))
    }

    return tokens
}

private func isKeyString(in line: String, after index: String.Index) -> Bool {
    var cursor = index
    while cursor < line.endIndex {
        let character = line[cursor]
        if character == " " || character == "\t" {
            cursor = line.index(after: cursor)
            continue
        }
        return character == ":"
    }
    return false
}

private func kindForOutsideToken(_ token: String) -> CodeTokenKind {
    switch token {
    case "true", "false":
        return .bool
    case "null":
        return .null
    case "{", "}", "[", "]", ":", ",":
        return .punctuation
    default:
        return .number
    }
}

private func columnContexts(document: JSONDocument, selectedPath: String) -> [ColumnContext] {
    var result: [ColumnContext] = []
    var currentPath = "$"
    var currentValue = document.root

    while currentValue.isContainer {
        let children = childNodes(for: currentValue, parentPath: currentPath)
        let selectedChild = children.first { child in
            child.path == selectedPath || isAncestor(child.path, of: selectedPath)
        }
        result.append(
            ColumnContext(
                id: currentPath,
                title: currentPath == "$" ? "$" : currentPath,
                children: children,
                selectedChildPath: selectedChild?.path
            )
        )

        guard let selectedChild, selectedChild.value.isContainer else {
            break
        }
        currentPath = selectedChild.path
        currentValue = selectedChild.value
    }

    return result
}

private func childNodes(for value: JSONValue, parentPath: String) -> [JSONChild] {
    switch value {
    case .object(let entries):
        return entries.map {
            JSONChild(
                name: $0.key,
                path: parentPath + jsonPathComponent(forKey: $0.key),
                value: $0.value
            )
        }
    case .array(let values):
        return values.enumerated().map { index, value in
            JSONChild(name: "[\(index)]", path: "\(parentPath)[\(index)]", value: value)
        }
    case .string, .number, .bool, .null:
        return []
    }
}

private func rawLines(for document: JSONDocument) -> [RawLine] {
    var lines: [RawLine] = []
    appendRawValue(
        document.root,
        path: "$",
        level: 0,
        prefix: "",
        suffix: "",
        lines: &lines
    )
    return lines
}

private func appendRawValue(
    _ value: JSONValue,
    path: String,
    level: Int,
    prefix: String,
    suffix: String,
    lines: inout [RawLine]
) {
    let indentation = String(repeating: "  ", count: level)

    func append(_ text: String, path: String?) {
        lines.append(RawLine(number: lines.count + 1, text: text, path: path))
    }

    switch value {
    case .object(let entries):
        if entries.isEmpty {
            append("\(indentation)\(prefix){}\(suffix)", path: path)
            return
        }

        append("\(indentation)\(prefix){", path: path)
        for (index, entry) in entries.enumerated() {
            appendRawValue(
                entry.value,
                path: path + jsonPathComponent(forKey: entry.key),
                level: level + 1,
                prefix: "\(jsonStringLiteral(entry.key)): ",
                suffix: index == entries.count - 1 ? "" : ",",
                lines: &lines
            )
        }
        append("\(indentation)}\(suffix)", path: path)

    case .array(let values):
        if values.isEmpty {
            append("\(indentation)\(prefix)[]\(suffix)", path: path)
            return
        }

        append("\(indentation)\(prefix)[", path: path)
        for (index, child) in values.enumerated() {
            appendRawValue(
                child,
                path: "\(path)[\(index)]",
                level: level + 1,
                prefix: "",
                suffix: index == values.count - 1 ? "" : ",",
                lines: &lines
            )
        }
        append("\(indentation)]\(suffix)", path: path)

    case .string, .number, .bool, .null:
        append("\(indentation)\(prefix)\(jsonScalarLiteral(value))\(suffix)", path: path)
    }
}

private func jsonScalarLiteral(_ value: JSONValue) -> String {
    switch value {
    case .string(let text):
        return jsonStringLiteral(text)
    case .number(let number):
        return number
    case .bool(let bool):
        return bool ? "true" : "false"
    case .null:
        return "null"
    case .object, .array:
        return value.shortDescription
    }
}

private func jsonStringLiteral(_ value: String) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: [value], options: [.withoutEscapingSlashes]),
          var text = String(data: data, encoding: .utf8),
          text.count >= 2
    else {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    text.removeFirst()
    text.removeLast()
    return text
}

func isAncestor(_ candidate: String, of path: String) -> Bool {
    guard candidate != path else { return true }
    if candidate == "$" {
        return path.hasPrefix("$.") || path.hasPrefix("$[")
    }
    return path.hasPrefix(candidate + ".") || path.hasPrefix(candidate + "[")
}

private func breadcrumbItems(for path: String) -> [BreadcrumbItem] {
    var items = [BreadcrumbItem(label: "$", path: "$")]
    guard path != "$" else {
        return items
    }

    for component in pathComponents(afterRoot: path) {
        let parent = items.last?.path ?? "$"
        let nextPath: String
        switch component {
        case .key(let key):
            nextPath = parent + jsonPathComponent(forKey: key)
            items.append(BreadcrumbItem(label: key, path: nextPath))
        case .arrayIndex(let index):
            nextPath = "\(parent)[\(index)]"
            items.append(BreadcrumbItem(label: "[\(index)]", path: nextPath))
        case .raw(let token):
            nextPath = parent == "$" ? "$\(token)" : "\(parent)\(token)"
            items.append(BreadcrumbItem(label: token, path: nextPath))
        }
    }

    return items
}

private func parentJSONPath(_ path: String) -> String? {
    let items = breadcrumbItems(for: path)
    guard items.count > 1 else {
        return nil
    }
    return items[items.count - 2].path
}

private enum JSONPathComponent {
    case key(String)
    case arrayIndex(Int)
    case raw(String)
}

private func pathComponents(afterRoot path: String) -> [JSONPathComponent] {
    var components: [JSONPathComponent] = []
    var cursor = path.index(after: path.startIndex)

    while cursor < path.endIndex {
        let character = path[cursor]

        if character == "." {
            let keyStart = path.index(after: cursor)
            var keyEnd = keyStart
            while keyEnd < path.endIndex, path[keyEnd] != ".", path[keyEnd] != "[" {
                keyEnd = path.index(after: keyEnd)
            }
            components.append(.key(String(path[keyStart..<keyEnd])))
            cursor = keyEnd
            continue
        }

        if character == "[" {
            guard let close = path[cursor...].firstIndex(of: "]") else {
                components.append(.raw(String(path[cursor...])))
                break
            }

            let tokenStart = path.index(after: cursor)
            let token = String(path[tokenStart..<close])
            if token.hasPrefix("\""), token.hasSuffix("\"") {
                let key = String(token.dropFirst().dropLast())
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")
                components.append(.key(key))
            } else if let index = Int(token) {
                components.append(.arrayIndex(index))
            } else {
                components.append(.raw("[\(token)]"))
            }
            cursor = path.index(after: close)
            continue
        }

        components.append(.raw(String(path[cursor...])))
        break
    }

    return components
}

private func jsonPathComponent(forKey key: String) -> String {
    let simple = key.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    if simple {
        return ".\(key)"
    }
    let escaped = key
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "[\"\(escaped)\"]"
}

private func typeColor(_ value: JSONValue, palette: LensPalette) -> Color {
    switch value {
    case .object:
        return palette.object.color
    case .array:
        return palette.array.color
    case .string:
        return palette.string.color
    case .number:
        return palette.number.color
    case .bool:
        return palette.bool.color
    case .null:
        return palette.null.color
    }
}

private func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

private func byteText(_ bytes: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

private extension Color {
    init?(hexString: String) {
        var text = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") {
            text.removeFirst()
        }

        guard [3, 6, 8].contains(text.count),
              text.range(of: #"^[0-9A-Fa-f]+$"#, options: .regularExpression) != nil
        else {
            return nil
        }

        if text.count == 3 {
            text = text.map { "\($0)\($0)" }.joined()
        }

        var value: UInt64 = 0
        Scanner(string: text).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if text.count == 8 {
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            alpha = Double(value & 0x0000_00FF) / 255
        } else {
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            alpha = 1
        }

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
