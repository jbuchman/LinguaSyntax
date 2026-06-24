//
//  String+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import NaturalLanguage

extension String {
    static let syntaxTaggerOptions: NLTagger.Options = [
        .joinNames,
        .omitWhitespace,
        .omitPunctuation,
        .omitOther
    ]

    /// Apply syntax highlighting to the attributed string.
    func highlightSyntax(theme: Theme, options: NLTagger.Options = Self.syntaxTaggerOptions) -> AttributedString {
        guard !self.isEmpty else {
            return AttributedString(self)
        }
        
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = self
        
        var attributedString = AttributedString()
        var currentIndex = startIndex
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: options) { tag, tokenRange in
            if currentIndex < tokenRange.lowerBound {
                attributedString.append(AttributedString(self[currentIndex..<tokenRange.lowerBound]))
            }

            let substring = self[tokenRange]
            if let attributedSubstring = tag?.attributedString(substring: substring, theme: theme) {
                attributedString.append(attributedSubstring)
            } else {
                attributedString.append(AttributedString(substring))
            }

            currentIndex = tokenRange.upperBound
            return true
        }

        if currentIndex < endIndex {
            attributedString.append(AttributedString(self[currentIndex..<endIndex]))
        }
        
        attributedString.backgroundColor = theme.backgroundColor
        return attributedString
    }
    
    var wordCount: Int {
        guard !self.isEmpty else {
            return 0
        }
        
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        let tokens = tokenizer.tokens(for: self.startIndex..<self.endIndex)
        return tokens.count
    }

    func partsOfSpeech(theme: Theme) -> AttributedString {
        guard !self.isEmpty else {
            return AttributedString()
        }
        
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = self
        var tags = [NLTag: Int]()
        tagger.enumerateTags(in: self.startIndex..<self.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: Self.syntaxTaggerOptions) { tag, tokenRange in
            guard let tag, tag != .other else {
                return true
            }
            tags[tag, default: 0] += 1
            return true
        }

        let separator: AttributedString = ": "
        let attributedStrings = tags.sorted(by: { $0.value > $1.value }).map { (tag, count) -> AttributedString in
            let label = tag.attributedString(string: tag.rawValue, theme: theme)
            var count = AttributedString(String(count))
            count.foregroundColor = .secondaryLabel
            count.font = theme.font
            return label + separator + count
        }
            
        return attributedStrings.joined(separator: "\n")
    }
}

extension Sequence where Element == AttributedString {
    /// Joins `AttributedString` elements efficiently.
    func joined(separator: AttributedString = AttributedString("")) -> AttributedString {
        self.reduce(into: AttributedString("")) { (result, element) in
            if !result.characters.isEmpty { result.append(separator) }
            result.append(element)
        }
    }
}
