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
        var attributedString = AttributedString(string)
        
        if let foregroundColor = theme.foregroundColor(for: self) {
            attributedString.foregroundColor = foregroundColor
        }
        
        if let underlineStyle = theme.underlineStyle(for: self) {
            attributedString.underlineStyle = underlineStyle
        }
        
        var font = theme.font
        if theme.isBold(for: self) || theme.isItalic(for: self) {
            if theme.isBold(for: self) {
                font = font.bold()
            }
            if theme.isItalic(for: self) {
                font = font.italic()
            }
        }
        attributedString.font = font
        
        return attributedString
    }
}
