//
//  AboutView.swift
//  maculate
//
//  Created by Evan Boehs on 11/24/24.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            // app icon
            Image(nsImage: (NSImage(named: "AppIcon"))!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
            // app name
            Text("Maculate")
                .font(.title)
            // app version
            Text("Version 1.0")
            
            // app description
            Text("Be the change ❤️")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(5)
            
            // app credits
            Text("© Copyright Toastcat LLC 2024")
                .font(.caption)
            Text("With Special Thanks to GMP, MPFR and the Qalculate! Project")
                .font(.caption)
        }.frame(minWidth: 300, minHeight: 300).padding()
    }
}

#Preview {
    AboutView()
}
