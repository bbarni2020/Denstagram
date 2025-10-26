//
//  ContentView.swift
//  Denstagram
//
//  Created by Balogh Barnabás on 2025. 10. 26..
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            InstagramWebView(isLoading: $isLoading)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }
        }
    }
}

#Preview {
    ContentView()
}
