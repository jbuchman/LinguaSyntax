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
        let customTheme = Self.loadCustomTheme()
        if let identifier = UserDefaults.standard.string(forKey: Constants.themeKey), identifier == "custom" {
            theme = .custom(customTheme)
        } else if let identifier = UserDefaults.standard.string(forKey: Constants.themeKey), let value = Theme.builtInTheme(for: identifier) {
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
            UserDefaults.standard.set(theme.identifier, forKey: Constants.themeKey)
            if case .custom(let customTheme) = theme {
                Self.save(customTheme: customTheme)
            }
        }
    }

    static func loadCustomTheme() -> CustomTheme {
        guard let data = UserDefaults.standard.data(forKey: Constants.customThemeKey),
              let customTheme = try? JSONDecoder().decode(CustomTheme.self, from: data) else {
            return CustomTheme()
        }

        return customTheme
    }

    private static func save(customTheme: CustomTheme) {
        guard let data = try? JSONEncoder().encode(customTheme) else {
            return
        }

        UserDefaults.standard.set(data, forKey: Constants.customThemeKey)
    }
}
