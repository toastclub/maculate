//
//  maculateApp.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var aboutBoxWindowController: NSWindowController?
    
    func showAboutPanel() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable,/* .resizable,*/ .titled, .fullSizeContentView]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About Maculate"
            
            window.titlebarAppearsTransparent = true
            let visualEffect = NSVisualEffectView()
            visualEffect.material = .sidebar
            visualEffect.blendingMode = .behindWindow
            visualEffect.state = .active
            window.contentView = visualEffect
            
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            
            window.center()
            
            window.contentView = NSHostingView(rootView: AboutView())
            aboutBoxWindowController = NSWindowController(window: window)
        }
        
        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
}

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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(VisualEffect().ignoresSafeArea())
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    appDelegate.showAboutPanel()
                }) {
                    Text("About Maculate")
                }
            }
        }
    }
}
