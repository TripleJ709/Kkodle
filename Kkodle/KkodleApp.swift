//
//  KkodleApp.swift
//  Kkodle
//
//  Created by 장주진 on 7/22/26.
//

import SwiftUI
import FirebaseCore

@main
struct KkodleApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
