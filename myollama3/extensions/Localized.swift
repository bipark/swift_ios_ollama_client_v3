//
//  Localized.swift
//  myollama3
//
//  Created by BillyPark on 5/13/25.
//

import SwiftUI


extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
