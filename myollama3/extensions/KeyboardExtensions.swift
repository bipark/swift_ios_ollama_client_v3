//
//  KeyboardExtensions.swift
//  myollama3
//
//  Created by BillyPark on 5/9/25.
//

import SwiftUI


extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if let window = windows.first(where: { $0.isKeyWindow }) {
            window.endEditing(true)
        }
    }
}


extension View {
    func hideKeyboard() {
        UIApplication.shared.dismissKeyboard()
    }
}


struct DismissKeyboardOnTap: ViewModifier {
    var focusState: FocusState<Bool>.Binding
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
                focusState.wrappedValue = false
            }
    }
}


extension View {
    func dismissKeyboardOnTap(focusState: FocusState<Bool>.Binding) -> some View {
        modifier(DismissKeyboardOnTap(focusState: focusState))
    }
} 