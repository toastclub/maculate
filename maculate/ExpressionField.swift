//
//  ExpressionField.swift
//  maculate
//
//  Created by Evan Boehs on 11/23/24.
//

import SwiftUI
import Qalculate
import SwiftUIIntrospect
import SwiftData

struct ExpressionFieldView: View {
    @State private var text: String = ""
    #if os(macOS)
    @State private var NSTextField: NSTextField?
    #endif
    @State private var cursorPosition: Int = 0
    @State private var relevantText: String?
    
    @AppStorage("hasEverInteracted") var hasEverInteracted = false
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        TextField("Enter an expression", text: $text)
            .padding(.top,35)
            .padding(.bottom,10)
            .padding(.horizontal)
            .textFieldStyle(.plain)
            .focusEffectDisabled()
            .introspect(.textField, on: .macOS(.v14,.v15)) { textView in
                DispatchQueue.main.async { NSTextField = textView }
            }.onChange(of: text) { oldValue, newValue in
                if let NSTextField = NSTextField {
                    // This should be the cursor position
                    let cursorPosition = NSTextField.currentEditor()?.selectedRange.location ?? 0
                    self.cursorPosition = cursorPosition
                    relevantText = getReleventText(text: newValue)
                }
            }
            .onSubmit {
                calculateExpression()
            }
            .modify {
                // The completion API is only available on macOS 15.0 and later.
                if #available(macOS 15.0, *) {
                    $0.textInputSuggestions {
                        if let relevantText = relevantText {
                            let completions = getCompletions(std.string(relevantText)).sorted { $0.name.count < $1.name.count }
                            ForEach(completions, id: \.name) { suggestion in
                                let theoreticalChange = self.theoreticalChange(completion: String(suggestion.name))
                                HStack {
                                    Text(String(suggestion.name))
                                    Spacer()
                                    Text(String(suggestion.description)).foregroundColor(.secondary)
                                }.textInputCompletion(theoreticalChange)
                            }
                        }
                    }
                }
            }
        }

    
    func calculateExpression() {
        let result = calculate(std.string(text))
        
        // split by \n, and get type and warnings by splitting from :
        let lines = String(result.messages).components(separatedBy: "\n")
        var messages: [Messages] = []
        for line in lines {
            let parts = line.split(separator: ": ", maxSplits: 1)
            if parts.count == 2 {
                let type = parts[0]
                let message = parts[1]
                if let messageType = MessageTypes(rawValue: String(type)) {
                    messages.append(Messages(type: messageType, message: String(message)))
                }
            }
        }
        
        let item = HistoryItem(
            expression: text,
            result: String(result.output),
            messages: messages
        )
        modelContext.insert(item)
    }
    
    /// Get the relevant text to use for completion
    /// For example, if the user types in 5newton, the relevant text is "newton"
    /// - Returns: The relevant text to use for
    func getReleventText(text: String) -> String? {
        if text.isEmpty || cursorPosition <= 0 {
            return nil
        }
        let previousCharIdx = text.index(text.startIndex, offsetBy: cursorPosition - 1)
        
        let previousChar = text[previousCharIdx]
        
        if !previousChar.isLetter {
            return nil
        }
        
        var relevantText = ""
        var idx = previousCharIdx
        while idx >= text.startIndex {
            if !text[idx].isLetter {
                break
            }
            relevantText = String(text[idx]) + relevantText
            if idx == text.startIndex {
                break
            }
            idx = text.index(before: idx)
        }
        return relevantText
    }
    
    /// Apply a theoretical change based on a completion.
    /// For example, if the user types in "5n", and selects "newton" from the completion list, the text will be "5newton".
    /// This takes into account the cursor position to insert the completion correctly.
    /// - Parameter completion: The suggested text to insert.
    /// - Returns: The new text after applying the change.
    func theoreticalChange(completion: String) -> String {
        guard cursorPosition >= 0 && cursorPosition <= text.count else {
            return text // If the cursor position is invalid, return the original text.
        }
        
        let startIndex = text.index(text.startIndex, offsetBy: cursorPosition)
        
        // Find the range of the "relevantText" in the current text.
        if let relevantText = relevantText {
            if let range = text.range(of: relevantText, options: .backwards, range: text.startIndex..<startIndex) {
                // Replace the relevantText with the completion.
                var newText = text
                newText.replaceSubrange(range, with: completion)
                return newText
            }
        }
        
        // If no relevantText is found, just insert the completion at the cursor position.
        var newText = text
        newText.insert(contentsOf: completion, at: startIndex)
        return newText
    }
}
