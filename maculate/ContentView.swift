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
            
            /* Display the output */
            if !output.isEmpty {
                Text("Answer is: \(output) 🤡")
            }
        }
        .padding()
    }
    
    private func calculateExpression() {
        let result = calculate(std.string(text))
        // Convert the result back to a Swift String
        output = String(result)
        
    }
}
#Preview {
    ContentView()
}
