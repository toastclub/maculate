//
//  ContentView.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI
import Qalculate


struct HistoryItem: Equatable,Hashable {
    let expression: String
    let result: String
    let id = UUID()
}

struct ContentView: View {
    @State private var text = ""
    @State private var output = ""
    @State var outputs: [HistoryItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ExpressionFieldView(text: $text, output: $output)
                .onChange(of: output) {
                    withAnimation(.bouncy) {
                        outputs.append(HistoryItem(expression: text, result: output))
                    }
                    text = ""
                }
            Divider().padding(0)
            ScrollView {
                LazyVStack {
                    ForEach(Array(outputs.reversed()), id: \.id) { item in
                        OutputView(item: item)
                    }
                }.padding(.top,5)
            }
            .background(Color(NSColor(named: "BlackNWhite")!).opacity(0.5))
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .ignoresSafeArea()
        .font(.system(size: 16))
    }
}
#Preview {
    ContentView()
}
