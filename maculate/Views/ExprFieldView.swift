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

#if os(iOS)
class TextFieldDelegate: NSObject, UITextFieldDelegate {

    var shouldReturn: (() -> Bool)?

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if let shouldReturn = shouldReturn {
            return shouldReturn()
        }
        else {
            return true
        }
    }
}
#endif

struct ExpressionFieldView: View {
    @State private var text: String = ""
#if os(macOS)
    @State private var NSTextField: NSTextField?
#else
    @State private var UITextField: UITextField?
    var fieldDelegate = TextFieldDelegate()
#endif
    @State private var cursorPosition: Int = 0
    @State private var relevantText: String?

    let replacementMap = [
        "functions": [
            "integrate": "∫",
            "integral": "∫",
            "sum": "Σ",
            "product": "Π",
            "sqrt": "√",
        ],
        "constants": [
            "pi": "π",
            "tau": "τ",
            "rho": "ρ",
            "phi": "φ",
        ],
    ]

    @AppStorage("hasEverInteracted") var hasEverInteracted = false
    @Environment(\.modelContext) var modelContext

    var body: some View {
        TextField("Enter an expression", text: $text)
#if os(macOS)
            .padding(.top,35)
            .introspect(.textField, on: .macOS(.v14,.v15)) { textView in
                DispatchQueue.main.async { NSTextField = textView }
            }
            .onSubmit {
                calculateExpression()
                self.text = ""
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
#else
            .padding(.top,25)
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled(true)
            .autocapitalization(.none)
            .introspect(.textField, on: .iOS(.v18)) { textView in
                DispatchQueue.main.async { UITextField = textView }
                fieldDelegate.shouldReturn = {
                    calculateExpression()
                    self.text = ""
                    return false
                }
                textView.delegate = fieldDelegate
            }
            .toolbar {
                if let relevantText = relevantText {
                    ToolbarItemGroup(placement: .keyboard) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) { // Adjust spacing as needed
                                let completions = getCompletions(std.string(relevantText))
                                        .sorted { $0.name.count < $1.name.count }
                                        .map {
                                            return (name: String($0.name), description: String($0.description))
                                        }
                                ForEach(completions, id: \.name) { suggestion in
                                    Button {
                                        self.text = theoreticalChange(completion: suggestion.name)
                                    } label: {
                                        Text(suggestion.name)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                        .font(.system(.callout, design: .monospaced))
                        .padding(EdgeInsets(top: 0, leading: -10, bottom: 0, trailing: -10))
                        .transition(.move(edge: .bottom))
                    }
                }
            }
#endif
            .padding(.bottom,10)
            .padding(.horizontal)
            .textFieldStyle(.plain)
            .focusEffectDisabled()
            .onChange(of: text) { oldValue, newValue in
#if os(macOS)
                if let NSTextField = NSTextField {
                    // This should be the cursor position
                    let cursorPosition = NSTextField.currentEditor()?.selectedRange.location ?? 0
                    self.cursorPosition = cursorPosition
                    // why did i write this? is it necessary?
                    NSTextField.currentEditor()?.selectedRange = NSRange(location: self.cursorPosition, length: 0)
                }
#else
                if let UITextField = UITextField {
                    let cursorPosition = UITextField.selectedTextRange?.start
                    self.cursorPosition = UITextField.offset(from: UITextField.beginningOfDocument, to: cursorPosition ?? UITextField.beginningOfDocument)
                    UITextField.selectedTextRange = UITextField.textRange(from: UITextField.position(from: UITextField.beginningOfDocument, offset: self.cursorPosition)!, to: UITextField.position(from: UITextField.beginningOfDocument, offset: self.cursorPosition)!)
                }
#endif
                self.text = replaceSymbols(text: newValue)
                relevantText = getReleventText(text: newValue)
            }
    }

    func replaceSymbols(text: String) -> String {
        guard cursorPosition > 0 else { return text }

        var updatedText = text

        /// Check if the range is preceded by a non-letter character.
        func isPrecededByNonLetter(_ range: Range<String.Index>, in text: String) -> Bool {
            guard range.lowerBound > text.startIndex else { return true }
            return !text[text.index(before: range.lowerBound)].isLetter
        }

        /// Check if the range is followed by specific valid characters.
        func isFollowedBy(_ range: Range<String.Index>, in text: String, validCharacters: [Character]) -> Bool {
            guard range.upperBound < text.endIndex else { return false }
            let nextChar = text[range.upperBound]
            return validCharacters.contains(nextChar) ||
            (nextChar == " " &&
             range.upperBound < text.index(before: text.endIndex) &&
             validCharacters.contains(text[text.index(after: range.upperBound)]))
        }

        /// Helper function to handle replacements based on specific rules.
        func replaceMatchingSymbols(from map: [String: String], validFollowingCharacters: [Character]) {
            for (key, symbol) in map {
                if let range = updatedText.range(of: key, options: .backwards, range: updatedText.startIndex..<updatedText.index(updatedText.startIndex, offsetBy: cursorPosition)),
                   isPrecededByNonLetter(range, in: updatedText),
                   isFollowedBy(range, in: updatedText, validCharacters: validFollowingCharacters) {
                    updatedText.replaceSubrange(range, with: symbol)
                    cursorPosition = updatedText.distance(from: updatedText.startIndex, to: range.lowerBound) + symbol.count
                    break
                }
            }
        }

        // Check for functions (followed by `(`)
        replaceMatchingSymbols(from: replacementMap["functions"] ?? [:], validFollowingCharacters: ["("])

        // Check for constants (followed by operators)
        replaceMatchingSymbols(from: replacementMap["constants"] ?? [:], validFollowingCharacters: ["*", "-", "/", "+", "^"])

        return updatedText
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
    /// For example, if the user types in 5newt, the relevant text is "newt"
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
