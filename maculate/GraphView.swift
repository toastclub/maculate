//
//  RenderGraph.swift
//  maculate
//
//  Created by Evan Boehs on 11/25/24.
//

import SwiftUI
import Charts

struct GraphView: View {
    @Binding var equation: String
    var body: some View {
        if #available(macOS 15.0, iOS 15.0, *) {
            Chart {
                LinePlot(x: "x", y: "y") { x in x * x }
            }
        }
    }
}

#Preview {
    GraphView(equation: .constant("x^2"))
}
