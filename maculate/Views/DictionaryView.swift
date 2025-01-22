//
//  DictionaryView.swift
//  maculate
//
//  Created by Evan Boehs on 1/22/25.
//

import SwiftUI
import Qalculate

let labels = [
    "Matrices & Vectors": "arrow.up.right",
    "Combinatorics": "tree",
    "Logical": "line.3.horizontal.decrease",
    "Number Theory": "numbers",
    "Special Functions": "function",
    "Complex Numbers": "numbersign",
    "Utilities": "gearshape",
    "Exponents & Logarithms": "exclamationmark.triangle",
    "Trigonometry": "triangle",
    "Statistics": "percent",
    "Date & Time": "clock",
    "Miscellaneous": "ellipsis",
    "Algebra": "xmark",
    "Calculus": "divide",
    "Geometry": "rotate.3d",
    "Economics": "dollarsign",
    "Data Sets": "list.bullet",
]

struct CategoryNode: Identifiable {
    let id = UUID()
    let name: String
    var children: [CategoryNode]?
}

// Helper function to build the hierarchy from category strings
func buildCategoryHierarchy(from items: [String]) -> [CategoryNode] {
    var rootNodes: [CategoryNode] = []
    
    for path in items {
        let components = path.split(separator: "/").map { String($0) }
        insertNode(components, into: &rootNodes)
    }
    
    return rootNodes
}

// Recursive function to insert nodes into the hierarchy
func insertNode(_ components: [String], into nodes: inout [CategoryNode]) {
    guard let first = components.first else { return }
    
    if let existingNodeIndex = nodes.firstIndex(where: { $0.name == first }) {
        if nodes[existingNodeIndex].children == nil {
            nodes[existingNodeIndex].children = []
        }
        if components.count > 1 {
            insertNode(Array(components.dropFirst()), into: &nodes[existingNodeIndex].children!)
        } else {
            nodes[existingNodeIndex].children = nil
        }
    } else {
        var newNode = CategoryNode(name: first, children: [])
        if components.count > 1 {
            insertNode(Array(components.dropFirst()), into: &newNode.children!)
        } else {
            newNode.children = nil
        }
        nodes.append(newNode)
    }
}

struct DictionaryView: View {
    @State var items = Array(getDictItems(DictType(0)))
    var hierarchy: [CategoryNode] {
        buildCategoryHierarchy(from: items.map { String($0.categories) })
    }
    var body: some View {
        NavigationSplitView {
            List {
                OutlineGroup(hierarchy, children: \.children) { node in
                    NavigationLink(destination: DictionarySectionListView(selectedItem: node.name, items: $items)) {
                        if let systemImage = labels[node.name] {
                            Label(node.name, systemImage: systemImage)
                        } else {
                            Text(node.name)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        } content: {
            ContentUnavailableView("Select an element from the sidebar", systemImage: "doc.text.image.fill")
        } detail: {
            ContentUnavailableView("Select an element from the sidebar", systemImage: "doc.text.image.fill")
        }.navigationTitle("Dictionary")
    }
}

struct DictionarySectionListView: View {
    var selectedItem: String
    @Binding var items: [DictItem]
    private var filteredItems: [String] {
        items.filter { String($0.categories) == selectedItem }.map { String($0.key) }
    }
    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                NavigationLink(destination: DictionaryItemView(selectedItem: item)) {
                    Text(item)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct DictionaryItemView: View {
    var selectedItem: String
    @Environment(\.font) var font
    var text: AttributedString {
        let md = String(getBodyForItem(std.string(selectedItem), DictType(0)))
        return try! AttributedString(markdown: md,options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }
    
    var body: some View {
        ScrollView {
            Text(text)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DictionaryView()
}
