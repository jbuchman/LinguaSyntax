//
//  NLTag+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//


import NaturalLanguage
import UIKit

extension NLTag {
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
