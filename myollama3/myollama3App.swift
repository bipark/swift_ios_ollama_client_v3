//
//  myollama3App.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI
import Toasts

@main
struct myollama3App: App {
    @AppStorage("has_seen_welcome") private var hasSeenWelcome = false
    
    init() {
        let appearance = UINavigationBar.appearance()
        appearance.tintColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.white
            default:
                return UIColor.black
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                ContentView()
                    .installToast(position: .top)
                    .accentColor(Color.appPrimary)
            } else {
                WelcomeView()
                    .installToast(position: .top)
                    .accentColor(Color.appPrimary)
            }
        }
    }
}
