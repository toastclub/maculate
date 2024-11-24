//
//  ExpressionField.swift
//  maculate
//
//  Created by Evan Boehs on 11/23/24.
//

import SwiftUI
import Qalculate
import SwiftUIIntrospect

struct ExpressionFieldView: View {
    @Binding var text: String
    @Binding var output: String
    #if os(macOS)
    @State private var NSTextField: NSTextField?
    #endif
    @State private var cursorPosition: Int = 0
    @State private var relevantText: String?
    
    var body: some View {
        TextField("Enter an expression", text: $text)
            .padding()
            .focusEffectDisabled()
            .introspect(.textField, on: .macOS(.v14,.v15)) { textView in
                DispatchQueue.main.async { NSTextField = textView }
            }.onChange(of: text) { oldValue, newValue in
                if let NSTextField = NSTextField {
                    let cursorPosition = NSTextField.currentEditor()?.selectedRange.location ?? 0
                    if (oldValue.count > newValue.count) {
                        self.cursorPosition = cursorPosition - 1
                    } else {
                        self.cursorPosition = cursorPosition
                    }
                    relevantText = getReleventText(text: newValue)
                }
            }
            .onSubmit {
                calculateExpression()
            }
            .modify {
                if #available(macOS 15.0, *) {
                    $0.textInputSuggestions {
                        if let relevantText = relevantText {
                            ForEach(getCompletions(std.string(relevantText)), id: \.name) { suggestion in
                                HStack {
                                    Text(String(suggestion.name))
                                    Spacer()
                                    Text(String(suggestion.description)).foregroundColor(.secondary)
                                }.textInputCompletion(text + String(suggestion.name))
                            }
                        }
                    }
                }
            }
                
        }

    
    func calculateExpression() {
        let result = calculate(std.string(text))
        output = String(result.output)
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
}
