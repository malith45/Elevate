//
//  ContentView.swift
//  Elevate
//
//  Created by COBSCCOMP24.2P-034 on 2026-03-30.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            MainTabView()
        } else {
            SignInView(isAuthenticated: $isAuthenticated)
        }
    }
}

#Preview {
    ContentView()
}
