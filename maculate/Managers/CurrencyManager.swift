//
//  CurrencyManager.swift
//  maculate
//
//  Created by Evan Boehs on 11/29/24.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ConversionRate {
    #Unique<ConversionRate>([\.fromCurrency, \.toCurrency])
    
    var fromCurrency: String
    var toCurrency: String
    var rate: Double
    var date: Date = Date()
    
    init(fromCurrency: String, toCurrency: String, rate: Double) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate
        self.date = Date()
    }
}

struct ConversionRatesApiResponse: Codable {
    let date: String
    let eur: [String: Double]
}

class CurrencyManager {
    static let shared = CurrencyManager()
    @AppStorage("lastUpdated") var lastUpdated = Date()
    @Environment(\.modelContext) var modelContext
    
    // fetch every 24 hours
    let timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
        Task {
            await shared.getConversionRates()
            shared.injectConversionRates()
        }
    }
    
    // todo: fetch from toastcat servers
    func getConversionRates() async {
        let url = URL(string: "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/eur.min.json")!
        let (data, _) = try! await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        // in the "eur" key, we have a dictionary of currency codes and their conversion rates
        let conversionRates = try! decoder.decode(ConversionRatesApiResponse.self, from: data)
        let conversionRatesArray = conversionRates.eur.map { ConversionRate(fromCurrency: "EUR", toCurrency: $0.key, rate: $0.value) }
        for rate in conversionRatesArray {
            modelContext.insert(rate)
        }
        try? modelContext.save()
        lastUpdated = Date()
    }
    
    // inject conversion rates into Qalculate
    func injectConversionRates() {
        // map to a \n delimited string in the form of CODE:RATE
        let conversionRates = try? modelContext.fetch(FetchDescriptor<ConversionRate>())
        let conversionRatesString = conversionRates?.map { "\($0.fromCurrency):\($0.toCurrency):\($0.rate)" }.joined(separator: "\n")
    }
}
