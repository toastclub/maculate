//
//  ContentView.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI
import Qalculate

enum MessageTypes: String {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
}

struct Messages: Equatable,Hashable {
    let type: MessageTypes
    let message: String
}

struct HistoryItem: Equatable,Hashable {
    let expression: String
    let result: String
    let messages: [Messages]
    let id = UUID()
}

struct ContentView: View {
    @State var outputs: [HistoryItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ExpressionFieldView(outputs: $outputs)
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
