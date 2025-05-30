//
//  AboutView.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(Color.appPrimary)
                            .padding(.bottom, 8)
                        
                        Text("l_myollama".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("l_local_llm_assistant".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                GroupBox(label: headerView(title: "l_about_app".localized, systemImage: "info.circle.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        contentText("l_about_app_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_key_features".localized, systemImage: "star.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        featureItem(title: "l_feature_models".localized, description: "l_feature_models_desc".localized)
                        
                        Divider()
                        
                        featureItem(title: "l_feature_image".localized, description: "l_feature_image_desc".localized)
                        
                        Divider()
                        
                        featureItem(title: "l_feature_history".localized, description: "l_feature_history_desc".localized)
                        
                        Divider()
                        
                        featureItem(title: "l_feature_share".localized, description: "l_feature_share_desc".localized)
                        
                        Divider()
                        
                        featureItem(title: "l_feature_params".localized, description: "l_feature_params_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_how_to_use".localized, systemImage: "book.fill")) {
                    VStack(alignment: .leading, spacing: 16) {
                        stepItem(number: 1, title: "l_step1".localized, description: "l_step1_desc".localized)
                        
                        stepItem(number: 2, title: "l_step2".localized, description: "l_step2_desc".localized)
                        
                        stepItem(number: 3, title: "l_step3".localized, description: "l_step3_desc".localized)
                        
                        stepItem(number: 4, title: "l_step4".localized, description: "l_step4_desc".localized)
                        
                        stepItem(number: 5, title: "l_step5".localized, description: "l_step5_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_tips".localized, systemImage: "lightbulb.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        tipItem(title: "l_tip1".localized, description: "l_tip1_desc".localized)
                        
                        Divider()
                        
                        tipItem(title: "l_tip2".localized, description: "l_tip2_desc".localized)
                        
                        Divider()
                        
                        tipItem(title: "l_tip3".localized, description: "l_tip3_desc".localized)
                        
                        Divider()
                        
                        tipItem(title: "l_tip4".localized, description: "l_tip4_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_system_requirements".localized, systemImage: "gear.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        contentText("l_system_requirements_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_privacy".localized, systemImage: "lock.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        contentText("l_privacy_desc".localized)
                    }
                    .padding(.top, 8)
                }
                
                GroupBox(label: headerView(title: "l_developer_info".localized, systemImage: "person.fill")) {
                    VStack(alignment: .leading, spacing: 12) {                        
                        Button(action: {
                            if let emailURL = URL(string: "mailto:rtlink.park@gmail.com?subject=My LLM%20피드백") {
                                UIApplication.shared.open(emailURL)
                            }
                        }) {
                            Label("l_send_feedback".localized, systemImage: "envelope.fill")
                                .foregroundColor(Color.appPrimary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("l_about_myollama".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func headerView(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(Color.appPrimary)
            Text(title)
                .font(.headline)
        }
    }
    
    private func contentText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func featureItem(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.appPrimary)
            
            Text(description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func stepItem(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.appPrimary)
                
                Text(description)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func tipItem(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.appPrimary)
            
            Text(description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

