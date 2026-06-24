//
//  LinguaSyntaxTests.swift
//  LinguaSyntaxTests
//
//  Created by Jeremy Buchman on 6/24/26.
//

import NaturalLanguage
import Testing
import UIKit
@testable import LinguaSyntax

@MainActor
struct TextViewTests {
    @Test func deleteWithCollapsedSelectionDoesNotDeleteText() {
        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.attributedText = NSAttributedString(string: "Alpha beta")
        textView.selectedRange = NSRange(location: 5, length: 0)

        textView.delete(nil)

        #expect(textView.attributedText.string == "Alpha beta")
        #expect(delegate.changeCount == 0)
    }

    @Test func cutWithCollapsedSelectionDoesNotDeleteText() {
        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.attributedText = NSAttributedString(string: "Alpha beta")
        textView.selectedRange = NSRange(location: 5, length: 0)

        textView.cut(nil)

        #expect(textView.attributedText.string == "Alpha beta")
        #expect(delegate.changeCount == 0)
    }

    @Test func deleteAllDeletesTextAndNotifiesOnce() {
        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.attributedText = NSAttributedString(string: "Alpha beta")

        textView.deleteAll()

        #expect(textView.attributedText.string.isEmpty)
        #expect(delegate.changeCount == 1)
    }

    @Test func pasteInsertsTextAtCollapsedSelectionAndNotifiesOnce() {
        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.pasteboardTextProvider = { [" beta"] }
        textView.attributedText = NSAttributedString(string: "Alpha")
        textView.selectedRange = NSRange(location: 5, length: 0)

        textView.paste(nil)

        #expect(textView.attributedText.string == "Alpha beta")
        #expect(textView.selectedRange == NSRange(location: 10, length: 0))
        #expect(delegate.changeCount == 1)
    }

    @Test func replaceAllWithPasteboardTextReplacesTextAndNotifiesOnce() {
        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.pasteboardTextProvider = { ["Replacement"] }
        textView.attributedText = NSAttributedString(string: "Original text")
        textView.selectedRange = NSRange(location: 8, length: 4)

        textView.replaceAllWithPasteboardText()

        #expect(textView.attributedText.string == "Replacement")
        #expect(textView.selectedRange == NSRange(location: 11, length: 0))
        #expect(delegate.changeCount == 1)
    }
}

struct StringExtensionTests {
    @Test func wordCountOmitsPunctuation() {
        #expect("Hello, world!".wordCount == 2)
    }

    @Test func partsOfSpeechOmitsPunctuationWhitespaceAndOtherTags() {
        let summaryText = String("Hello, world!").partsOfSpeech(theme: .dark).characters

        #expect(!summaryText.contains(NLTag.punctuation.rawValue))
        #expect(!summaryText.contains(NLTag.whitespace.rawValue))
        #expect(!summaryText.contains(NLTag.other.rawValue))
    }
}

struct ThemeTests {
    @Test func builtInThemesHaveDisplayNames() {
        let themeNames = Theme.builtInThemes.map(\.name)

        #expect(themeNames == [
            "Office",
            "Scholastic",
            "Editorial",
            "Blueprint",
            "Dark"
        ])
    }

    @Test func customThemeUsesStoredStyle() {
        var customTheme = CustomTheme()
        customTheme.interfaceStyle = .light
        customTheme.backgroundColor = ThemeColor(red: 1, green: 1, blue: 1)
        customTheme.tagStyles[NLTag.noun.rawValue] = CustomTagStyle(
            color: ThemeColor(red: 0.1, green: 0.2, blue: 0.3),
            isBold: true,
            isItalic: true,
            isUnderlined: true
        )

        let theme = Theme.custom(customTheme)

        #expect(theme.name == "Custom")
        #expect(theme.interfaceStyle == .light)
        #expect(theme.isBold(for: .noun))
        #expect(theme.isItalic(for: .noun))
        #expect(theme.underlineStyle(for: .noun) == .single)
        #expect(theme.foregroundColor(for: .noun) == UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1))
    }
}

private final class ChangeCountingDelegate: NSObject, UITextViewDelegate {
    var changeCount = 0

    func textViewDidChange(_ textView: UITextView) {
        changeCount += 1
    }
}
