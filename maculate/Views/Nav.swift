//
//  TapeSwitcher.swift
//  maculate
//
//  Created by Evan Boehs on 1/21/25.
//

import SwiftUI

struct TapeSwitcher: View {
    @Binding var tape: String
    
    var body: some View {
        Button {
            tape = ""
        } label: {
            Label("DEFAULT", systemImage: "chevron.down")
        }
        // make the button have a background color of the accent color
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.accentColor)
    }
}

struct Nav: View {
    @Binding var tape: String
    var body: some View {
        HStack {
            #if os(macOS)
            Spacer()
            #endif
            TapeSwitcher(tape: $tape)
        }.padding()
    }
}

#Preview {
    Nav(tape: .constant("x^2"))
}
