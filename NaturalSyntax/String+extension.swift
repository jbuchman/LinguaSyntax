//
//  String+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import NaturalLanguage

extension String {
    /// Apply syntax highlighting to the attributed string.
    func highlightSyntax(theme: Theme = .dark, options: NLTagger.Options = [.joinNames]) -> AttributedString {
        let text = self
        guard !text.isEmpty else { return AttributedString(self) }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = self
        
        var attributedString = AttributedString()
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let substring = text[tokenRange]
            if let attributedSubstring = tag?.attributedString(string: substring, theme: theme) {
                attributedString.append(attributedSubstring)
            } else {
                attributedString.append(AttributedString(substring))
            }
            return true
        }
        
        attributedString.backgroundColor = theme.backgroundColor
        return attributedString
    }
}

