//
//  Extensions.swift
//  maculate
//
//  Created by Evan Boehs on 11/23/24.
//

import SwiftUI

enum OperatingSystem {
    case macOS
    case iOS
    case tvOS
    case watchOS
    
#if os(macOS)
    static let current = macOS
#elseif os(iOS)
    static let current = iOS
#elseif os(tvOS)
    static let current = tvOS
#elseif os(watchOS)
    static let current = watchOS
#else
#error("Unsupported platform")
#endif
}

extension View {
    @ViewBuilder
    func modify(@ViewBuilder _ transform: (Self) -> (some View)?) -> some View {
        if let view = transform(self), !(view is EmptyView) {
            view
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifOS<Content: View>(
        _ operatingSystems: OperatingSystem...,
        modifier: (Self) -> Content
    ) -> some View {
        if operatingSystems.contains(OperatingSystem.current) {
            modifier(self)
        } else {
            self
        }
    }
}
