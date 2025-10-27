//
//  CustomNavBar.swift
//  Denstagram
//
//  Created by Balogh Barnabás on 2025. 10. 27..
//

import SwiftUI

struct CustomNavBar: View {
    @Binding var selectedTab: NavTab
    
    enum NavTab {
        case dms
        case search
        case notifications
        case profile
        case signout
    }
    
    var body: some View {
        HStack(spacing: 0) {
            NavButton(
                icon: "paperplane",
                title: "Messages",
                isSelected: selectedTab == .dms
            ) {
                selectedTab = .dms
            }
            
            NavButton(
                icon: "magnifyingglass",
                title: "Search",
                isSelected: selectedTab == .search
            ) {
                selectedTab = .search
            }
            
            NavButton(
                icon: "heart",
                title: "Notifications",
                isSelected: selectedTab == .notifications
            ) {
                selectedTab = .notifications
            }
            
            NavButton(
                icon: "person.crop.circle",
                title: "Profile",
                isSelected: selectedTab == .profile
            ) {
                selectedTab = .profile
            }
            
            NavButton(
                icon: "arrow.right.square",
                title: "Sign Out",
                isSelected: selectedTab == .signout
            ) {
                selectedTab = .signout
            }
        }
        .frame(height: 49)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 0, x: 0, y: -0.5)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.33)
                .foregroundColor(Color(UIColor.separator).opacity(0.6)),
            alignment: .top
        )
    }
}

struct NavButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private var displayIcon: String {
        if isSelected {
            switch icon {
            case "magnifyingglass", "arrow.right.square":
                return icon
            default:
                return "\(icon).fill"
            }
        }
        return icon
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: displayIcon)
                    .font(.system(size: 24, weight: .regular))
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .foregroundColor(isSelected ? .primary : Color(UIColor.secondaryLabel))
        }
        .buttonStyle(.plain)
    }
}
