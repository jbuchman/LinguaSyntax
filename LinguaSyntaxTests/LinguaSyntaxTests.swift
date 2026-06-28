//
//  LinguaSyntaxTests.swift
//  LinguaSyntaxTests
//
//  Created by Jeremy Buchman on 6/24/26.
//

import AppIntents
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

    @Test(arguments: [
        ("Spanish", "Hola mundo. Adiós mundo.", 4),
        ("French", "Bonjour le monde. Merci beaucoup.", 5),
        ("Japanese", "今日は世界です。明日も書きます。", 8),
        ("Arabic", "مرحبا بالعالم. شكرا جزيلا.", 4)
    ])
    func wordCountHandlesMultipleLanguages(_ language: String, text: String, expectedWordCount: Int) {
        #expect(text.wordCount == expectedWordCount, "\(language) word count changed")
    }

    @Test(arguments: [
        "Hola mundo. Adiós mundo.",
        "Bonjour le monde. Merci beaucoup.",
        "今日は世界です。明日も書きます。",
        "مرحبا بالعالم. شكرا جزيلا."
    ])
    func syntaxHighlightingPreservesMultilingualText(_ text: String) {
        #expect(String(text.highlightSyntax(theme: .dark).characters) == text)
    }

    @Test(arguments: [
        "Hola mundo. Adiós mundo.",
        "Bonjour le monde. Merci beaucoup.",
        "今日は世界です。明日も書きます。",
        "مرحبا بالعالم. شكرا جزيلا."
    ])
    func partsOfSpeechOmitsNonLexicalTagsForMultipleLanguages(_ text: String) {
        let summaryText = text.partsOfSpeech(theme: .dark).characters

        #expect(!summaryText.contains(NLTag.punctuation.rawValue))
        #expect(!summaryText.contains(NLTag.whitespace.rawValue))
        #expect(!summaryText.contains(NLTag.other.rawValue))
    }

    @Test func textInputLanguageCodeCreatesNaturalLanguageHint() throws {
        let language = try #require(NLLanguage(textInputPrimaryLanguage: "es-MX"))

        #expect(language.rawValue == "es-MX")
    }

    @Test(arguments: [nil, "emoji"])
    func invalidTextInputLanguageCodeDoesNotCreateNaturalLanguageHint(_ languageCode: String?) {
        #expect(NLLanguage(textInputPrimaryLanguage: languageCode) == nil)
    }

    @Test func syntaxHighlightingAcceptsLanguageHint() {
        let text = "Hola mundo."

        #expect(String(text.highlightSyntax(theme: .dark, languageHint: .spanish).characters) == text)
    }

    @Test func partsOfSpeechAcceptsLanguageHint() {
        let summaryText = "Hola mundo.".partsOfSpeech(theme: .dark, languageHint: .spanish).characters

        #expect(!summaryText.isEmpty)
        #expect(!summaryText.contains(NLTag.punctuation.rawValue))
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

    @Test func customThemeCanUseBuiltInThemeAsBasis() {
        let customTheme = CustomTheme(basedOn: Theme.blueprint)
        let theme = Theme.custom(customTheme)

        #expect(theme.interfaceStyle == Theme.blueprint.interfaceStyle)
        #expect(theme.backgroundColor == Theme.blueprint.backgroundColor)
        #expect(theme.foregroundColor(for: .verb) == Theme.blueprint.foregroundColor(for: .verb))
        #expect(theme.foregroundColor(for: .noun) == Theme.blueprint.foregroundColor(for: .noun))
    }
}

@MainActor
struct ShortcutTests {
    @Test func exportRTFIntentCreatesStyledRTFDataFromInputText() throws {
        let data = try ExportRTFIntent.rtfData(for: "Shortcut text", theme: .blueprint)
        let exportedText = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        let backgroundColor = exportedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor

        #expect(exportedText.string == "Shortcut text")
        #expect(backgroundColor?.hasSameRGBAComponents(as: Theme.blueprint.backgroundColor) == true)
    }

    @Test func exportPartsOfSpeechIntentCreatesTextFile() throws {
        let file = try ExportPartsOfSpeechIntent.outputFile(
            for: "The quick fox jumps.",
            outputFormat: .text,
            theme: .blueprint
        )
        let text = String(data: file.data, encoding: .utf8)

        #expect(file.filename == "LinguaSyntax Parts of Speech.txt")
        #expect(file.type == .plainText)
        #expect(text?.isEmpty == false)
        #expect(text?.contains(":") == true)
    }

    @Test func exportPartsOfSpeechIntentCreatesStyledRTFFile() throws {
        let file = try ExportPartsOfSpeechIntent.outputFile(
            for: "The quick fox jumps.",
            outputFormat: .rtf,
            theme: .blueprint
        )
        let exportedText = try NSAttributedString(
            data: file.data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        let backgroundColor = exportedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor

        #expect(file.filename == "LinguaSyntax Parts of Speech.rtf")
        #expect(file.type == .rtf)
        #expect(exportedText.string.isEmpty == false)
        #expect(backgroundColor?.hasSameRGBAComponents(as: Theme.blueprint.backgroundColor) == true)
    }
}

@MainActor
struct CounterViewControllerTests {
    @Test func rtfExportIncludesThemeBackgroundColor() throws {
        let attributedText = NSAttributedString(
            string: "Styled text",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.systemRed
            ]
        )

        let data = try CounterViewController.rtfData(from: attributedText, theme: .blueprint)
        let exportedText = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        let backgroundColor = exportedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor

        #expect(exportedText.string == "Styled text")
        #expect(backgroundColor?.hasSameRGBAComponents(as: Theme.blueprint.backgroundColor) == true)
    }
}

struct CounterSheetDetentTests {
    @Test func keyboardVisibleDetentsOmitMediumDetent() {
        #expect(ViewController.counterSheetDetentIdentifiers(isKeyboardVisible: true) == [
            Constants.minimizedIdentifier,
            Constants.keyboardTextViewHalfIdentifier,
            .large
        ])
    }

    @Test func keyboardHiddenDetentsIncludeMediumDetent() {
        #expect(ViewController.counterSheetDetentIdentifiers(isKeyboardVisible: false) == [
            Constants.minimizedIdentifier,
            .medium,
            .large
        ])
    }

    @Test func keyboardHalfDetentUsesHalfOfAvailableHeightAboveKeyboard() {
        let height = ViewController.keyboardTextViewHalfDetentHeight(
            viewHeight: 800,
            keyboardOverlapHeight: 300,
            maximumDetentValue: 800
        )

        #expect(height == 550)
    }

    @Test func keyboardHalfDetentIsCappedToMaximumDetentValue() {
        let height = ViewController.keyboardTextViewHalfDetentHeight(
            viewHeight: 800,
            keyboardOverlapHeight: 300,
            maximumDetentValue: 500
        )

        #expect(height == 500)
    }
}

struct ShareImportTests {
    @Test func importURLExtractsSharedText() throws {
        var components = URLComponents()
        components.scheme = Constants.importURLScheme
        components.host = Constants.importURLHost
        components.queryItems = [
            URLQueryItem(name: Constants.importTextQueryItem, value: "Imported text")
        ]

        let url = try #require(components.url)

        #expect(SceneDelegate.importedText(from: url) == "Imported text")
    }

    @Test func importURLRejectsUnknownScheme() throws {
        let url = try #require(URL(string: "https://example.com?text=Imported"))

        #expect(SceneDelegate.importedText(from: url) == nil)
    }

    @Test func pendingImportURLIsRecognizedWithoutInlineText() throws {
        var components = URLComponents()
        components.scheme = Constants.importURLScheme
        components.host = Constants.importURLHost

        let url = try #require(components.url)

        #expect(SceneDelegate.isImportURL(url))
        #expect(SceneDelegate.importedText(from: url) == nil)
    }

    @Test func importsPendingSharedTextFromFile() throws {
        let fileURL = try #require(TextImporter.pendingSharedTextFileURL())
        try "Pending file text".write(to: fileURL, atomically: true, encoding: .utf8)

        let importedText = TextImporter.importPendingSharedText()

        #expect(importedText == "Pending file text")
        #expect(UserDefaults.standard.string(forKey: Constants.textKey) == "Pending file text")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test func importsPendingSharedText() throws {
        let sharedDefaults = try #require(UserDefaults(suiteName: Constants.appGroupIdentifier))
        sharedDefaults.set("Pending shared text", forKey: Constants.pendingSharedTextKey)

        let importedText = TextImporter.importPendingSharedText()

        #expect(importedText == "Pending shared text")
        #expect(UserDefaults.standard.string(forKey: Constants.textKey) == "Pending shared text")
        #expect(sharedDefaults.string(forKey: Constants.pendingSharedTextKey) == nil)
    }
}

private final class ChangeCountingDelegate: NSObject, UITextViewDelegate {
    var changeCount = 0

    func textViewDidChange(_ textView: UITextView) {
        changeCount += 1
    }
}

private extension UIColor {
    func hasSameRGBAComponents(as otherColor: UIColor, accuracy: CGFloat = 0.001) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        var otherRed: CGFloat = 0
        var otherGreen: CGFloat = 0
        var otherBlue: CGFloat = 0
        var otherAlpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha),
              otherColor.getRed(&otherRed, green: &otherGreen, blue: &otherBlue, alpha: &otherAlpha) else {
            return false
        }

        return abs(red - otherRed) <= accuracy
            && abs(green - otherGreen) <= accuracy
            && abs(blue - otherBlue) <= accuracy
            && abs(alpha - otherAlpha) <= accuracy
    }
}
