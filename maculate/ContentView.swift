//
//  ContentView.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI
import Qalculate

struct ContentView: View {
    @State private var text = ""
    @State private var output = ""
    
    var body: some View {
        VStack {
            /* Create a text field to input the expression */
            TextField("Enter an expression", text: $text)
                .padding()
                .onSubmit {
                    calculateExpression()
                }
                .textInputSuggestions {
                    Text("The Fillmore")
                        .textInputCompletion("1805 Geary Blvd, San Francisco")
                    Text("The Catalyst")
                        .textInputCompletion("1011 Pacific Ave, Santa Cruz")
                    Text("Rio Theatre")
                        .textInputCompletion("1205 Soquel Ave, Santa Cruz")
                }
            
            /* Display the output */
            if !output.isEmpty {
                Text("Answer is: \(output)").background(VisualEffect())
            }
        }
        .padding()
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .ignoresSafeArea()
    }
    
    private func pickRandomEmoji() -> String {
        let emojis = ["🤡", "🤓", "💀", "🫵"]
        return emojis.randomElement()!
    }
    
    private func calculateExpression() {
        let result = calculate(std.string(text))
        // Convert the result back to a Swift String

        let attributed = try! NSAttributedString(data: String(result.output).data(using: .unicode)!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)

        output = attributed.string + " " + pickRandomEmoji()
        
    }
}
#Preview {
    ContentView()
}
