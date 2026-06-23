//
//  Settings.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/22/26.
//

import Combine
import UIKit

class Settings: ObservableObject {
    init() {
        if let name = UserDefaults.standard.string(forKey: Constants.themeKey), let value = Theme(rawValue: name) {
            theme = value
        } else {
            theme = .dark
        }

        if let string = UserDefaults.standard.string(forKey: Constants.textKey) {
            text = string
        } else {
            text = ""
        }
    }

    @Published var text: String {
        didSet {
            UserDefaults.standard.set(text, forKey: Constants.textKey)
        }
    }

    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: Constants.themeKey)
        }
    }
}
