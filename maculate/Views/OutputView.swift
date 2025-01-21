//
//  OutputView.swift
//  maculate
//
//  References: https://github.com/jherkenhoff/qalculate-android/blob/main/app/src/main/java/com/jherkenhoff/qalculate/ui/common/mathExpressionFormatter.kt
//
//  Created by Evan Boehs on 11/24/24.
//

import SwiftUI

func styledOutput(_ text: String) -> AttributedString {
    var text = text
    var attributedString = AttributedString()

    var tagHandlers: [String: (Substring) -> AttributedString] = [:]

    func processText(_ text: Substring) -> AttributedString {
        var result = AttributedString()
        var currentIndex = text.startIndex

        while currentIndex < text.endIndex {
            // Find the next tag
            if let tagStart = text.range(of: "<", range: currentIndex..<text.endIndex),
               let tagEnd = text.range(of: ">", range: tagStart.upperBound..<text.endIndex) {

                // Append normal text before the tag
                if currentIndex < tagStart.lowerBound {
                    result.append(AttributedString(text[currentIndex..<tagStart.lowerBound]))
                }

                // Determine the tag name
                let tagName = text[tagStart.upperBound..<tagEnd.lowerBound]

                if let closeTagStart = text.range(of: "</\(tagName)>", range: tagEnd.upperBound..<text.endIndex),
                   let handler = tagHandlers[String(tagName)] {
                    // Handle the tag using its handler
                    let tagContent = text[tagEnd.upperBound..<closeTagStart.lowerBound]
                    result.append(handler(tagContent))
                    currentIndex = closeTagStart.upperBound
                } else {
                    // Skip unsupported or malformed tags
                    currentIndex = tagEnd.upperBound
                }
            } else {
                // No more tags; append remaining text
                result.append(AttributedString(text[currentIndex..<text.endIndex]))
                break
            }
        }
        return result
    }

    tagHandlers = [
        "i": { content in
            var styledText = processText(content) // Recursively process content
            styledText.font = .system(size: 16, design: .serif).italic()
            return styledText
        },
        "sup": { content in
            var styledText = processText(content)
            styledText.baselineOffset = 6
            styledText.font = .system(size: 14)
            return styledText
        },
        "sub": { content in
            var styledText = processText(content)
            styledText.baselineOffset = -6
            styledText.font = .system(size: 14)
            return styledText
        }
    ]
    
    text = text
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&amp;", with: "&")
    
    attributedString = processText(text[...])
    return attributedString
}

struct OutputView: View {
    var item: HistoryItem
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.expression)
                    .fontDesign(.monospaced)
                    .padding([.leading,.trailing])
                    .textSelection(.enabled)
                if item.starred {
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .padding(.trailing)
                }
            }
            Text(styledOutput(item.result))
                .padding([.leading,.trailing])
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)
            ForEach(item.messages, id: \.self) { message in
                switch message.type {
                    case .error:
                        Label(message.message, systemImage: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                    case .warning:
                        Label(message.message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    case .info:
                        Label(message.message, systemImage: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                }
            }
            .padding([.leading,.trailing])
            .font(.caption)
            Divider()
        }
        .modify {
            if item.specialStatus?.contains(.tutorial) == true {
                $0.foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top))
        .contextMenu {
            Button("Copy Expression") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.expression, forType: .string)
            }
            Button("Copy Result") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.result, forType: .string)
            }
            Divider()
            Button("Star", systemImage: item.starred ? "star.fill" : "star") {
                item.starred.toggle()
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                modelContext.delete(item)
            }
        }
    }
}
