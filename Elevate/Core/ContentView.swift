//
//  ContentView.swift
//  Elevate
//
//  Created by COBSCCOMP24.2P-034 on 2026-03-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appSession: AppSession
    
    @State private var activeNotification: NotificationItem?
    
    var body: some View {
        ZStack(alignment: .top) {
            if let user = appSession.currentUser {
                if user.role.lowercased() == "manager" || user.role.lowercased() == "owner" {
                    ManagerMainTabView()
                } else {
                    MainTabView()
                }
            } else {
                SignInView()
            }
            
            if let notification = activeNotification {
                InAppNotificationToast(notification: notification) {
                    withAnimation {
                        activeNotification = nil
                    }
                }
                .padding(.top, 60)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            activeNotification = nil
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowInAppNotification"))) { notification in
            if let item = notification.object as? NotificationItem {
                withAnimation(.spring()) {
                    activeNotification = item
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSession())
}
