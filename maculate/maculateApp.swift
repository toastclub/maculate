//
//  maculateApp.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI

struct VisualEffect: NSViewRepresentable {
    func makeNSView(context: Self.Context) -> NSView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) { }
}
@main
struct maculateApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(VisualEffect().ignoresSafeArea())
        }.windowStyle(.hiddenTitleBar)
    }
}
