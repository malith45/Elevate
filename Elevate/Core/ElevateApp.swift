//
//  ElevateApp.swift
//  Elevate
//
//  Created by COBSCCOMP24.2P-034 on 2026-03-30.
//

import SwiftUI
import FirebaseCore

@main
struct ElevateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appSession = AppSession()

    init() {
        FirebaseApp.configure()
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .fontDesign(.rounded)
                .withGlobalAccessibilitySettings()
                .environmentObject(appSession)
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == "elevate" else { return }
        
        if url.host == "job", let jobId = url.pathComponents.last {
            TechnicianTabRouter.shared.handleWidgetDeepLink(jobId: jobId)
        }
    }
}
