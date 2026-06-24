//
//  Theme.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import SwiftUI
import NaturalLanguage

public enum Theme: Equatable {
    case office, scholastic, editorial, blueprint, dark
    case custom(CustomTheme)

    public static let builtInThemes: [Theme] = [.office, .scholastic, .editorial, .blueprint, .dark]

    var identifier: String {
        switch self {
        case .office: return "office"
        case .scholastic: return "scholastic"
        case .editorial: return "editorial"
        case .blueprint: return "blueprint"
        case .dark: return "dark"
        case .custom: return "custom"
        }
    }

    static func builtInTheme(for identifier: String) -> Theme? {
        builtInThemes.first { $0.identifier == identifier }
    }

    var isCustom: Bool {
        if case .custom = self {
            return true
        }
        return false
    }

    func secondaryBackground(traitCollection: UITraitCollection) -> UIColor {
        let baseTraits = traitCollection.modifyingTraits { mutableTraits in
            // Explicitly downgrade the sheet's elevation level to flat base
            mutableTraits.userInterfaceLevel = .base
            mutableTraits.userInterfaceStyle = interfaceStyle
        }

        return UIColor.secondarySystemBackground.resolvedColor(with: baseTraits)
    }

    var name: String {
        switch self {
        case .office: return String(localized: "Office")
        case .scholastic: return String(localized: "Scholastic")
        case .editorial: return String(localized: "Editorial")
        case .blueprint: return String(localized: "Blueprint")
        case .dark: return String(localized: "Dark")
        case .custom(let customTheme): return customTheme.name
        }
    }

    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .blueprint, .dark: return .dark
        case .custom(let customTheme): return customTheme.interfaceStyle.uiUserInterfaceStyle
        default: return .light
        }
    }

    public var backgroundColor: UIColor {
        switch self {
        case .editorial: return UIColor(red: 0.98, green: 0.97, blue: 0.93, alpha: 1)
        case .blueprint: return UIColor(red: 0.02, green: 0.08, blue: 0.14, alpha: 1)
        case .dark: return UIColor(white: 0.2, alpha: 1)
        case .custom(let customTheme): return customTheme.backgroundColor.uiColor
        default: return .white
        }
    }

    public func underlineStyle(for tag: NLTag) -> NSUnderlineStyle? {
        switch self {
        case .dark where tag == .placeName:
            return .single
        case .custom(let customTheme):
            return customTheme.style(for: tag).isUnderlined ? .single : nil
        default:
            return nil
        }
    }

    public func isBold(for tag: NLTag) -> Bool {
        switch self {
        case .dark where tag == .personalName:
            return true
        case .custom(let customTheme):
            return customTheme.style(for: tag).isBold
        default:
            return false
        }
    }

    public func isItalic(for tag: NLTag) -> Bool {
        switch self {
        case .dark where tag == .organizationName:
            return true
        case .custom(let customTheme):
            return customTheme.style(for: tag).isItalic
        default:
            return false
        }
    }

    public var font: UIFont {
        .preferredFont(forTextStyle: .body)
    }

    public static func textAttributes(theme: Theme) -> [NSAttributedString.Key: Any] {
        [
            .font: theme.font,
            .foregroundColor: UIColor.label
        ]
    }

    public func foregroundColor(for tag: NLTag) -> UIColor? {
        switch self {
            // Microsoft Office
        case .office where tag == .noun:             return #colorLiteral(red: 0.662745098, green: 0.1411764706, blue: 0.6549019608, alpha: 1)
        case .office where tag == .verb:             return #colorLiteral(red: 0.5529411765, green: 0.05490196078, blue: 0.07450980392, alpha: 1)
        case .office where tag == .adjective:        return #colorLiteral(red: 0.1058823529, green: 0.5176470588, blue: 0.2274509804, alpha: 1)

            // Editorial
        case .editorial where [.placeName, .organizationName, .personalName].contains(tag): return UIColor(red: 0.00, green: 0.42, blue: 0.68, alpha: 1)
        case .editorial where tag == .noun:          return UIColor(red: 0.04, green: 0.21, blue: 0.44, alpha: 1)
        case .editorial where tag == .pronoun:       return UIColor(red: 0.35, green: 0.20, blue: 0.55, alpha: 1)
        case .editorial where tag == .verb:          return UIColor(red: 0.88, green: 0.11, blue: 0.12, alpha: 1)
        case .editorial where tag == .adverb:        return UIColor(red: 0.72, green: 0.18, blue: 0.52, alpha: 1)
        case .editorial where tag == .adjective:     return UIColor(red: 0.00, green: 0.50, blue: 0.18, alpha: 1)
        case .editorial where tag == .preposition:   return UIColor(red: 0.86, green: 0.47, blue: 0.00, alpha: 1)
        case .editorial where tag == .determiner:    return UIColor(red: 0.25, green: 0.35, blue: 0.40, alpha: 1)
        case .editorial where tag == .conjunction:   return UIColor(red: 0.55, green: 0.28, blue: 0.10, alpha: 1)
        case .editorial where tag == .number:        return UIColor(red: 0.65, green: 0.48, blue: 0.00, alpha: 1)

            // Blueprint
        case .blueprint where [.placeName, .organizationName, .personalName].contains(tag): return UIColor(red: 0.48, green: 0.93, blue: 1.00, alpha: 1)
        case .blueprint where tag == .noun:          return UIColor(red: 0.83, green: 0.95, blue: 1.00, alpha: 1)
        case .blueprint where tag == .pronoun:       return UIColor(red: 0.70, green: 0.78, blue: 1.00, alpha: 1)
        case .blueprint where tag == .particle:      return UIColor(red: 0.43, green: 0.78, blue: 0.86, alpha: 1)
        case .blueprint where tag == .verb:          return UIColor(red: 1.00, green: 0.82, blue: 0.33, alpha: 1)
        case .blueprint where tag == .adverb:        return UIColor(red: 1.00, green: 0.58, blue: 0.77, alpha: 1)
        case .blueprint where tag == .adjective:     return UIColor(red: 0.48, green: 1.00, blue: 0.75, alpha: 1)
        case .blueprint where tag == .interjection:  return UIColor(red: 1.00, green: 0.67, blue: 0.42, alpha: 1)
        case .blueprint where tag == .preposition:   return UIColor(red: 0.92, green: 0.90, blue: 0.70, alpha: 1)
        case .blueprint where tag == .determiner:    return UIColor(red: 0.62, green: 0.78, blue: 0.86, alpha: 1)
        case .blueprint where tag == .conjunction:   return UIColor(red: 0.80, green: 0.68, blue: 1.00, alpha: 1)
        case .blueprint where tag == .number:        return UIColor(red: 1.00, green: 0.94, blue: 0.56, alpha: 1)

            // Dark theme
        case .dark where [.placeName, .organizationName, .personalName, .noun].contains(tag): return #colorLiteral(red: 0.968627451, green: 0.568627451, blue: 0.3647058824, alpha: 1)
        case .dark where tag == .pronoun:            return #colorLiteral(red: 0.968627451, green: 0.9362080227, blue: 0.3647058824, alpha: 1)
        case .dark where tag == .particle:           return #colorLiteral(red: 0.4078431373, green: 0.6039215686, blue: 0.7921568627, alpha: 1)
        case .dark where tag == .number:             return #colorLiteral(red: 0.9098039216, green: 0.9019607843, blue: 0.8745098039, alpha: 1)
        case .dark where tag == .verb:               return #colorLiteral(red: 0.7960784314, green: 0.6039215686, blue: 0.7960784314, alpha: 1)
        case .dark where tag == .adverb:             return #colorLiteral(red: 0.9411764706, green: 0.4705882353, blue: 0.4862745098, alpha: 1)
        case .dark where tag == .adjective:          return #colorLiteral(red: 0.4078431373, green: 0.6039215686, blue: 0.7921568627, alpha: 1)
        case .dark where tag == .interjection:       return #colorLiteral(red: 0.4156862745, green: 0.8, blue: 0.7960784314, alpha: 1)
        case .dark where tag == .preposition:        return #colorLiteral(red: 0.9960784314, green: 0.7960784314, blue: 0.431372549, alpha: 1)
        case .dark where tag == .determiner:         return #colorLiteral(red: 0.6039215686, green: 0.7960784314, blue: 0.6078431373, alpha: 1)
        case .dark where tag == .conjunction:        return #colorLiteral(red: 0.8156862745, green: 0.4823529412, blue: 0.3411764706, alpha: 1)
        case .dark where [.other, .classifier, .idiom, .wordJoiner, .word, .otherWord].contains(tag): return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case .dark where [.openParenthesis, .closeParenthesis, .dash, .closeQuote, .openQuote, .paragraphBreak, .sentenceTerminator, .punctuation, .whitespace].contains(tag): return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)

            // Scholastic
        case .scholastic where tag == .noun:         return #colorLiteral(red: 0, green: 0.5803921569, blue: 0.7764705882, alpha: 1)
        case .scholastic where tag == .verb:         return #colorLiteral(red: 0.7607843137, green: 0.1490196078, blue: 0.1882352941, alpha: 1)
        case .scholastic where tag == .adjective:    return #colorLiteral(red: 0.5725490196, green: 0.7098039216, blue: 0.2588235294, alpha: 1)

        case .custom(let customTheme):
            return customTheme.style(for: tag).color.uiColor

        default:
            return nil
        }
    }
}

public struct CustomTheme: Codable, Equatable {
    public enum InterfaceStyle: String, Codable, Equatable, CaseIterable {
        case light, dark

        var uiUserInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    public var name: String
    public var interfaceStyle: InterfaceStyle
    public var backgroundColor: ThemeColor
    public var tagStyles: [String: CustomTagStyle]

    public init(
        name: String = String(localized: "Custom"),
        interfaceStyle: InterfaceStyle = .dark,
        backgroundColor: ThemeColor = ThemeColor(red: 0.09, green: 0.10, blue: 0.12),
        tagStyles: [String: CustomTagStyle] = CustomTheme.defaultTagStyles
    ) {
        self.name = name
        self.interfaceStyle = interfaceStyle
        self.backgroundColor = backgroundColor
        self.tagStyles = tagStyles
    }

    public init(basedOn theme: Theme) {
        if case .custom(let customTheme) = theme {
            self = customTheme
            return
        }

        let interfaceStyle: InterfaceStyle = theme.interfaceStyle == .dark ? .dark : .light
        let defaultStyle = CustomTagStyle.default(interfaceStyle: interfaceStyle)
        let tagStyles = Self.editableTags.reduce(into: [String: CustomTagStyle]()) { result, tag in
            result[tag.rawValue] = CustomTagStyle(
                color: ThemeColor(color: theme.foregroundColor(for: tag) ?? defaultStyle.color.uiColor),
                isBold: theme.isBold(for: tag),
                isItalic: theme.isItalic(for: tag),
                isUnderlined: theme.underlineStyle(for: tag) != nil
            )
        }

        self.init(
            name: String(localized: "Custom"),
            interfaceStyle: interfaceStyle,
            backgroundColor: ThemeColor(color: theme.backgroundColor),
            tagStyles: tagStyles
        )
    }

    public static let editableTags: [NLTag] = [
        .noun,
        .verb,
        .adjective,
        .adverb,
        .pronoun,
        .preposition,
        .determiner,
        .conjunction,
        .number,
        .placeName,
        .organizationName,
        .personalName
    ]

    public static let defaultTagStyles: [String: CustomTagStyle] = [
        NLTag.noun.rawValue: CustomTagStyle(color: ThemeColor(red: 0.95, green: 0.68, blue: 0.34)),
        NLTag.verb.rawValue: CustomTagStyle(color: ThemeColor(red: 0.72, green: 0.58, blue: 0.96)),
        NLTag.adjective.rawValue: CustomTagStyle(color: ThemeColor(red: 0.42, green: 0.74, blue: 0.96)),
        NLTag.adverb.rawValue: CustomTagStyle(color: ThemeColor(red: 0.96, green: 0.48, blue: 0.56)),
        NLTag.pronoun.rawValue: CustomTagStyle(color: ThemeColor(red: 0.94, green: 0.87, blue: 0.38)),
        NLTag.preposition.rawValue: CustomTagStyle(color: ThemeColor(red: 0.96, green: 0.72, blue: 0.42)),
        NLTag.determiner.rawValue: CustomTagStyle(color: ThemeColor(red: 0.58, green: 0.80, blue: 0.60)),
        NLTag.conjunction.rawValue: CustomTagStyle(color: ThemeColor(red: 0.82, green: 0.48, blue: 0.34)),
        NLTag.number.rawValue: CustomTagStyle(color: ThemeColor(red: 0.88, green: 0.88, blue: 0.82)),
        NLTag.placeName.rawValue: CustomTagStyle(color: ThemeColor(red: 0.96, green: 0.62, blue: 0.38), isUnderlined: true),
        NLTag.organizationName.rawValue: CustomTagStyle(color: ThemeColor(red: 0.96, green: 0.62, blue: 0.38), isItalic: true),
        NLTag.personalName.rawValue: CustomTagStyle(color: ThemeColor(red: 0.96, green: 0.62, blue: 0.38), isBold: true)
    ]

    public func style(for tag: NLTag) -> CustomTagStyle {
        tagStyles[tag.rawValue] ?? CustomTagStyle.default(interfaceStyle: interfaceStyle)
    }
}

public struct CustomTagStyle: Codable, Equatable {
    public var color: ThemeColor
    public var isBold: Bool
    public var isItalic: Bool
    public var isUnderlined: Bool

    public init(color: ThemeColor, isBold: Bool = false, isItalic: Bool = false, isUnderlined: Bool = false) {
        self.color = color
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
    }

    static func `default`(interfaceStyle: CustomTheme.InterfaceStyle) -> CustomTagStyle {
        switch interfaceStyle {
        case .light:
            return CustomTagStyle(color: ThemeColor(red: 0.12, green: 0.12, blue: 0.12))
        case .dark:
            return CustomTagStyle(color: ThemeColor(red: 0.88, green: 0.88, blue: 0.88))
        }
    }
}

public struct ThemeColor: Codable, Equatable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
