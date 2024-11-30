//
//  maculateApp.swift
//  maculate
//
//  Created by Evan Boehs on 11/21/24.
//

import SwiftUI
import SwiftData

#if os(macOS)
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
#endif

enum AngleUnit: String, CaseIterable, Identifiable {
    case degrees, radians, gradians, arcminutes, arcseconds, turns, none
    var id: String { self.rawValue }
}

@main
struct maculateApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    @AppStorage("angleUnit") var angleUnit = AngleUnit.degrees

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modify {
                    if #available(macOS 15.0, iOS 18.0, *) {
                        $0.modelContainer(for: ConversionRate.self)
                    }
                }
#if os(macOS)
                .background(VisualEffect().ignoresSafeArea())
#endif
        }
        .modelContainer(for: HistoryItem.self)
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    appDelegate.showAboutPanel()
                }) {
                    Text("About Maculate")
                }
            }
            CommandGroup(before: .toolbar) {
                Section {
                    Picker("Angle Unit", selection: $angleUnit) {
                        ForEach(AngleUnit.allCases) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                }
            }
        }
#endif
    }
}
