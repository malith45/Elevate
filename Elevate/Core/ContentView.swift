//
//  ContentView.swift
//  Elevate
//
//  Created by COBSCCOMP24.2P-034 on 2026-03-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appSession: AppSession
    
    var body: some View {
        if let user = appSession.currentUser {
            if user.role.lowercased() == "manager" || user.role.lowercased() == "owner" {
                ManagerMainTabView()
            } else {
                MainTabView()
            }
        } else {
            SignInView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSession())
}
