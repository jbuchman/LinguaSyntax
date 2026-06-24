//
//  LinguaSyntaxTests.swift
//  LinguaSyntaxTests
//
//  Created by Jeremy Buchman on 6/24/26.
//

import NaturalLanguage
import Testing
import UIKit
import UniformTypeIdentifiers
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
        let oldPasteboardItems = UIPasteboard.general.items
        defer { UIPasteboard.general.items = oldPasteboardItems }

        UIPasteboard.general.items = [
            [UTType.plainText.identifier: " beta"]
        ]

        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
        textView.attributedText = NSAttributedString(string: "Alpha")
        textView.selectedRange = NSRange(location: 5, length: 0)

        textView.paste(nil)

        #expect(textView.attributedText.string == "Alpha beta")
        #expect(textView.selectedRange == NSRange(location: 10, length: 0))
        #expect(delegate.changeCount == 1)
    }

    @Test func replaceAllWithPasteboardTextReplacesTextAndNotifiesOnce() {
        let oldPasteboardItems = UIPasteboard.general.items
        defer { UIPasteboard.general.items = oldPasteboardItems }

        UIPasteboard.general.items = [
            [UTType.plainText.identifier: "Replacement"]
        ]

        let textView = TextView()
        let delegate = ChangeCountingDelegate()
        textView.delegate = delegate
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
        let themeNames = Theme.allCases.map(\.name)

        #expect(themeNames == [
            "Office",
            "Scholastic",
            "Editorial",
            "Blueprint",
            "Dark"
        ])
    }
}

private final class ChangeCountingDelegate: NSObject, UITextViewDelegate {
    var changeCount = 0

    func textViewDidChange(_ textView: UITextView) {
        changeCount += 1
    }
}
