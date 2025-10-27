//
//  ContentView.swift
//  Denstagram
//
//  Created by Balogh Barnabás on 2025. 10. 26..
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = false
    @State private var selectedTab: CustomNavBar.NavTab = .dms
    @State private var targetURL = "https://www.instagram.com/direct/inbox/"
    @State private var showSignOutAlert = false
    @State private var isSignedOut = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    InstagramWebView(isLoading: $isLoading, targetURL: $targetURL, isSignedOut: $isSignedOut)
                    
                    if isLoading {
                        InstagramLoadingView()
                    }
                }
                
                if !isSignedOut {
                    CustomNavBar(selectedTab: $selectedTab)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .onChange(of: selectedTab) { oldTab, newTab in
                switch newTab {
                case .dms:
                    targetURL = "https://www.instagram.com/direct/inbox/"
                case .search:
                    targetURL = "https://www.instagram.com/explore/people/"
                case .notifications:
                    targetURL = "https://www.instagram.com/?show_notifications=true"
                case .profile:
                    targetURL = "https://www.instagram.com/accounts/edit/"
                case .signout:
                    showSignOutAlert = true
                    selectedTab = oldTab
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    isSignedOut = true
                    
                    let dataStore = WKWebsiteDataStore.default()
                    dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                           for: records.filter { $0.displayName.contains("instagram") },
                                           completionHandler: {
                            DispatchQueue.main.async {
                                targetURL = "https://www.instagram.com/accounts/login/"
                            }
                        })
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            
            if showSplash {
                InstagramSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
