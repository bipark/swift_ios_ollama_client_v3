import SwiftUI

struct AppColor {
    static func adaptiveColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    static var primary: Color {
        return adaptiveColor(light: .black, dark: .white)
    }
    
    static var userMessageBackground: Color {
        return adaptiveColor(light: .black, dark: .gray)
    }
    
    static var link: Color {
        return adaptiveColor(light: .blue, dark: .blue)
    }
    
    static var icon: Color {
        return adaptiveColor(light: .black.opacity(0.7), dark: .white.opacity(0.7))
    }
    
    static var buttonActive: Color {
        return adaptiveColor(light: .black, dark: .white)
    }
    
    static var appIcon: Color {
        return primary
    }
}

extension Color {
    static var appPrimary: Color {
        return AppColor.primary
    }
    
    static var appUserMessage: Color {
        return AppColor.userMessageBackground
    }
    
    static var appLink: Color {
        return AppColor.link
    }
    
    static var appIcon: Color {
        return AppColor.icon
    }
    
    static var appButtonActive: Color {
        return AppColor.buttonActive
    }
} 
