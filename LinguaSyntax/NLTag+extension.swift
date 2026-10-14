//
//  NLTag+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//


import NaturalLanguage
import UIKit

extension NLTag {
    var localizedName: String {
        switch self {
        case .noun: return String(localized: "Noun")
        case .verb: return String(localized: "Verb")
        case .adjective: return String(localized: "Adjective")
        case .adverb: return String(localized: "Adverb")
        case .pronoun: return String(localized: "Pronoun")
        case .determiner: return String(localized: "Determiner")
        case .particle: return String(localized: "Particle")
        case .preposition: return String(localized: "Preposition")
        case .number: return String(localized: "Number")
        case .conjunction: return String(localized: "Conjunction")
        case .interjection: return String(localized: "Interjection")
        case .classifier: return String(localized: "Classifier")
        case .idiom: return String(localized: "Idiom")
        case .otherWord: return String(localized: "Other Word")
        case .personalName: return String(localized: "Personal Name")
        case .placeName: return String(localized: "Place Name")
        case .organizationName: return String(localized: "Organization Name")
        default: return rawValue
        }
    }


    /// Apply tag attributes to the specified range.
    public func attributedString(substring: Substring, theme: Theme) -> AttributedString {
        attributedString(string: String(substring), theme: theme)
    }
    
    public func attributedString(string: String, theme: Theme) -> AttributedString {
        let style = textStyle(theme: theme)
        var attributedString = AttributedString(string)
        
        if let foregroundColor = style.foregroundColor {
            attributedString.foregroundColor = foregroundColor
        }
        
        if let underlineStyle = style.underlineStyle {
            attributedString.underlineStyle = underlineStyle
        }
        
        attributedString.font = style.font
        
        return attributedString
    }

    public func textAttributes(theme: Theme) -> [NSAttributedString.Key: Any] {
        let style = textStyle(theme: theme)
        var attributes = Theme.textAttributes(theme: theme)

        if let foregroundColor = style.foregroundColor {
            attributes[.foregroundColor] = foregroundColor
        }

        if let underlineStyle = style.underlineStyle {
            attributes[.underlineStyle] = underlineStyle.rawValue
        }

        attributes[.font] = style.font
        return attributes
    }

    private func textStyle(theme: Theme) -> TagTextStyle {
        var font = theme.font
        if theme.isBold(for: self) {
            font = font.bold()
        }
        if theme.isItalic(for: self) {
            font = font.italic()
        }
        return TagTextStyle(
            foregroundColor: theme.foregroundColor(for: self),
            underlineStyle: theme.underlineStyle(for: self),
            font: font
        )
    }
}

private struct TagTextStyle {
    let foregroundColor: UIColor?
    let underlineStyle: NSUnderlineStyle?
    let font: UIFont
}
