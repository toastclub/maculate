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
        VStack {
            ExpressionFieldView(text: $text, output: $output)
                .onChange(of: output) {
                    withAnimation(.bouncy) {
                        outputs.append(HistoryItem(expression: text, result: output))
                    }
                    text = ""
                }
            ScrollView {
                LazyVStack {
                    ForEach(Array(outputs.reversed()), id: \.id) { item in
                        VStack(alignment: .leading) {
                            Text(item.expression)
                                .fontDesign(.monospaced)
                                .padding([.leading,.trailing])
                            Text(item.result)
                                .padding([.leading,.trailing])
                            // use first because the list is reversed
                            if item.id != outputs.first?.id {
                                Divider()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .top))
                    }
                    
                }
            }
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
