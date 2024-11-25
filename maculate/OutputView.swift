//
//  OutputView.swift
//  maculate
//
//  Created by Evan Boehs on 11/24/24.
//

import SwiftUI

func styledOutput(_ text: String) -> AttributedString {
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
            var styledText = processText(content) // Recursively process content
            styledText.baselineOffset = 6 // Adjust as needed for superscript
            styledText.font = .system(size: 14)
            return styledText
        }
    ]

    attributedString = processText(text[...])
    return attributedString
}

struct OutputView: View {
    var item: HistoryItem
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.expression)
                .fontDesign(.monospaced)
                .padding([.leading,.trailing])
                .textSelection(.enabled)
            Text(styledOutput(item.result))
                .padding([.leading,.trailing])
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top))
    }
}
