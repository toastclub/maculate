//
//  ContentView.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // outputs sorted by date
    @Query(sort: \HistoryItem.date, order: .reverse, animation: .bouncy(duration: 0.2)) var outputs: [HistoryItem]
    @AppStorage("hasEverInteracted") var hasEverInteracted = false
    @Environment(\.modelContext) var modelContext

    var body: some View {
        VStack(spacing: 0) {
            ExpressionFieldView()
                .frame(maxWidth: .infinity)
            Divider().padding(0)
            if outputs.isEmpty {
                VStack {
                    Spacer()
                    Image("Ghost")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 128, height: 128)
                    Text("You found the ghost!")
                        .font(.title2)
                    Text("You win nothing!")
                        .font(.title3)
                    Spacer()
                }
                .foregroundColor(.secondary.opacity(0.7))
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity
                )
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(outputs, id: \.id) { item in
                            OutputView(item: item)
                        }
                        Button("Clear History") {
                            // save the model context before deletion to delete uncommitted changes
                            try? modelContext.save()
                            try? modelContext.delete(model: HistoryItem.self)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                        .font(.callout)
                    }.padding(.top,5)
                }
#if os(macOS)
                .background(Color(NSColor(named: "BlackNWhite")!).opacity(0.5))
#endif
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .ignoresSafeArea()
        .font(.system(size: 16))
        .onAppear {
            if #available(macOS 15.0, iOS 18.0, *) {
                let currencyManager = CurrencyManager(modelContext: modelContext)
                Task {
                    await currencyManager.getConversionRates()
                    currencyManager.injectConversionRates()
                }
            }
            if !hasEverInteracted {
                modelContext.insert(HistoryItem(expression: "2x + x^2 = 40", result: "<i>x</i> = 4 || <i>x</i> = −6", messages: [],specialStatus: [.tutorial]))
                modelContext.insert(HistoryItem(expression: "(G * planet(earth; mass) * planet(mars; mass)) / (54.6e6 km)^2", result: "85.80 PN", messages: [],specialStatus: [.tutorial]))
                modelContext.insert(HistoryItem(expression: "∫(x^2 + 2x + 1)", result: "<i>x</i><sup>3</sup>/2 + x<sup>2</sup> + x + C", messages: [],specialStatus: [.tutorial]))
                modelContext.insert(HistoryItem(expression: "1978 to roman", result: "MCMLXXVIII",messages: [],specialStatus: [.tutorial]))
                modelContext.insert(HistoryItem(expression: "50 Ω * 2 A", result: "100 V", messages: [],specialStatus: [.tutorial]))
            }
        }
    }
}
#Preview {
    ContentView()
}
