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
            ExpressionFieldView(text: $text, output: $output)
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
}
#Preview {
    ContentView()
}
