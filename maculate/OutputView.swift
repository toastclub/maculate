//
//  OutputView.swift
//  maculate
//
//  Created by Evan Boehs on 11/24/24.
//

import SwiftUI

func styledOutput(_ text: String) -> AttributedString {
    var attributedString = AttributedString()
    
    var currentIndex = text.startIndex
    
    while currentIndex < text.endIndex {
        // Find the next tag
        if let tagStart = text.range(of: "<", range: currentIndex..<text.endIndex),
           let tagEnd = text.range(of: ">", range: tagStart.upperBound..<text.endIndex) {
            
            // Append normal text before the tag
            if currentIndex < tagStart.lowerBound {
                attributedString.append(AttributedString(text[currentIndex..<tagStart.lowerBound]))
            }
            
            // Handle specific tags
            let tagName = text[tagStart.upperBound..<tagEnd.lowerBound]
            if tagName == "i" {
                // Find the corresponding closing tag
                if let closeTagStart = text.range(of: "</i>", range: tagEnd.upperBound..<text.endIndex) {
                    let italicTextRange = tagEnd.upperBound..<closeTagStart.lowerBound
                    var italicText = AttributedString(text[italicTextRange])
                    italicText.font = .system(size: 16, design: .serif).italic()
                    attributedString.append(italicText)
                    
                    currentIndex = closeTagStart.upperBound // Move past the closing tag
                    continue
                }
            } else if tagName == "sup" {
                // Find the corresponding closing tag
                if let closeTagStart = text.range(of: "</sup>", range: tagEnd.upperBound..<text.endIndex) {
                    let superscriptTextRange = tagEnd.upperBound..<closeTagStart.lowerBound
                    var superscriptText = AttributedString(text[superscriptTextRange])
                    //superscriptText.font = .systemFont(ofSize: UIFont.systemFontSize)
                    superscriptText.baselineOffset = CGFloat(14) * 0.3 // Adjust baseline offset
                    attributedString.append(superscriptText)
                    
                    currentIndex = closeTagStart.upperBound // Move past the closing tag
                    continue
                }
            }
            
            // Skip unsupported tags
            currentIndex = tagEnd.upperBound
        } else {
            // No more tags; append remaining text
            attributedString.append(AttributedString(text[currentIndex..<text.endIndex]))
            break
        }
    }

    
    return attributedString
}

struct OutputView: View {
    var item: HistoryItem
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.expression)
                .fontDesign(.monospaced)
                .padding([.leading,.trailing])
            Text(styledOutput(item.result))
                .padding([.leading,.trailing])
            Divider()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .top))
    }
}
