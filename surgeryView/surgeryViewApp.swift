//
//  surgeryViewApp.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import SwiftUI

@main
struct surgeryViewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
