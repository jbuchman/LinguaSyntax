//
//  Theme.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import SwiftUI
import NaturalLanguage

public enum Theme: String, CaseIterable {
    case office, scholastic, dark
    
    func secondaryBackground(traitCollection: UITraitCollection) -> UIColor {
        let baseTraits = traitCollection.modifyingTraits { mutableTraits in
            // Explicitly downgrade the sheet's elevation level to flat base
            mutableTraits.userInterfaceLevel = .base
            mutableTraits.userInterfaceStyle = interfaceStyle
        }

        return UIColor.secondarySystemBackground.resolvedColor(with: baseTraits)
    }
    
    var name: String {
        switch self
        {
        case .office: return "Office"
        case .scholastic: return "Scholastic"
        case .dark: return "Dark"
        }
    }
    
    public var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .dark: .dark
        default: .light
        }
    }
    
    public var backgroundColor: UIColor {
        switch self {
        case .dark: return UIColor(white: 0.2, alpha: 1)
        default: return .white
        }
    }

    public func underlineStyle(for tag: NLTag) -> NSUnderlineStyle? {
        switch (self, tag) {
        case (.dark, .placeName): return .single
        default: return nil
        }
    }
    
    public func isBold(for tag: NLTag) -> Bool {
        switch (self, tag) {
        case (.dark, .personalName): return true
        default: return false
        }
    }
    
    public func isItalic(for tag: NLTag) -> Bool {
        switch (self, tag) {
        case (.dark, .organizationName): return true
        default: return false
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
        switch (self, tag) {
            // Microsoft Office
        case (.office, .noun):             return #colorLiteral(red: 0.662745098, green: 0.1411764706, blue: 0.6549019608, alpha: 1)
        case (.office, .verb):             return #colorLiteral(red: 0.5529411765, green: 0.05490196078, blue: 0.07450980392, alpha: 1)   
        case (.office, .adjective):        return #colorLiteral(red: 0.1058823529, green: 0.5176470588, blue: 0.2274509804, alpha: 1)
            
            // Dark theme
        case (.dark, .placeName):          return #colorLiteral(red: 0.968627451, green: 0.568627451, blue: 0.3647058824, alpha: 1)
        case (.dark, .organizationName):   return #colorLiteral(red: 0.968627451, green: 0.568627451, blue: 0.3647058824, alpha: 1)
        case (.dark, .personalName):       return #colorLiteral(red: 0.968627451, green: 0.568627451, blue: 0.3647058824, alpha: 1)
        case (.dark, .noun):               return #colorLiteral(red: 0.968627451, green: 0.568627451, blue: 0.3647058824, alpha: 1)
        case (.dark, .pronoun):            return #colorLiteral(red: 0.968627451, green: 0.9362080227, blue: 0.3647058824, alpha: 1)
        case (.dark, .particle):           return #colorLiteral(red: 0.4078431373, green: 0.6039215686, blue: 0.7921568627, alpha: 1)
        case (.dark, .number):             return #colorLiteral(red: 0.9098039216, green: 0.9019607843, blue: 0.8745098039, alpha: 1)
        case (.dark, .verb):               return #colorLiteral(red: 0.7960784314, green: 0.6039215686, blue: 0.7960784314, alpha: 1)
        case (.dark, .adverb):             return #colorLiteral(red: 0.9411764706, green: 0.4705882353, blue: 0.4862745098, alpha: 1)
        case (.dark, .adjective):          return #colorLiteral(red: 0.4078431373, green: 0.6039215686, blue: 0.7921568627, alpha: 1)
        case (.dark, .interjection):       return #colorLiteral(red: 0.4156862745, green: 0.8, blue: 0.7960784314, alpha: 1)
        case (.dark, .preposition):        return #colorLiteral(red: 0.9960784314, green: 0.7960784314, blue: 0.431372549, alpha: 1)
        case (.dark, .determiner):         return #colorLiteral(red: 0.6039215686, green: 0.7960784314, blue: 0.6078431373, alpha: 1)
        case (.dark, .conjunction):        return #colorLiteral(red: 0.8156862745, green: 0.4823529412, blue: 0.3411764706, alpha: 1)
        case (.dark, .other):              return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .classifier):         return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .idiom):              return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .wordJoiner):         return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .word):               return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .otherWord):          return #colorLiteral(red: 0.8274509804, green: 0.8156862745, blue: 0.7843137255, alpha: 1)
        case (.dark, .openParenthesis):    return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .closeParenthesis):   return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .dash):               return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .closeQuote):         return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .openQuote):          return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .paragraphBreak):     return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .sentenceTerminator): return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .punctuation):        return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
        case (.dark, .whitespace):         return #colorLiteral(red: 0.9490196078, green: 0.9411764706, blue: 0.9254901961, alpha: 1)
            
            // Scholastic
        case (.scholastic, .noun):         return #colorLiteral(red: 0, green: 0.5803921569, blue: 0.7764705882, alpha: 1)
        case (.scholastic, .verb):         return #colorLiteral(red: 0.7607843137, green: 0.1490196078, blue: 0.1882352941, alpha: 1)
        case (.scholastic, .adjective):    return #colorLiteral(red: 0.5725490196, green: 0.7098039216, blue: 0.2588235294, alpha: 1)
            
        default: return nil
        }
    }
}
