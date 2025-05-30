//
//  WelcomeView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("has_seen_welcome") private var hasSeenWelcome = false
    @State private var showSettings = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    
    private let pageCount = 3
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    hasSeenWelcome = true
                }) {
                    Text("l_cancel".localized)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text("l_myollama".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("l_local_llm_assistant".localized)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            TabView(selection: $currentPage) {
                // "l_welcome_first_page".localized
                featureView(
                    iconName: "exclamationmark.triangle.fill",
                    title: "l_important".localized,
                    description: "l_welcome_server_setup_required".localized + "\n\n" + "l_welcome_server_explanation".localized,
                    iconColor: .orange
                )
                .tag(0)
                
                featureView(
                    iconName: "gear",
                    title: "l_setup_steps".localized,
                    description: "l_step1_desc".localized,
                    iconColor: Color.appPrimary
                )
                .tag(1)
                
                featureView(
                    iconName: "star.fill",
                    title: "l_key_features".localized,
                    description: "l_feature_models_desc".localized + "\n\n" + "l_feature_image_desc".localized,
                    iconColor: Color.appPrimary
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 460)
            
            Spacer()
            
            Button(action: {
                showSettings = true
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("l_setup_server_now".localized)
                }
                .font(.headline)
                .foregroundColor(AppColor.link)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColor.userMessageBackground)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            Button(action: {
                hasSeenWelcome = true
            }) {
                Text("l_continue_without_setup".localized)
                    .foregroundColor(Color.appPrimary)
                    .padding(.vertical, 8)
            }
            .padding(.bottom, 40)
        }
        .animation(.easeInOut, value: currentPage)
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView()
                    .navigationBarItems(trailing: Button("l_done".localized) {
                        showSettings = false
                        hasSeenWelcome = true
                    })
            }
        }
    }
    
    private func featureView(iconName: String, title: String, description: String, iconColor: Color) -> some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
