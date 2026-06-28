//
//  LinguaSyntaxShortcuts.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import AppIntents
import Foundation
import UniformTypeIdentifiers

struct ImportTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Import Text"
    static var description = IntentDescription("Open LinguaSyntax with the provided text.")
    static var openAppWhenRun = true

    @Parameter(title: "Text")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Import \(\.$text) into LinguaSyntax")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TextImporter.importText(text)
        return .result(dialog: "Imported text into LinguaSyntax.")
    }
}

struct CountWordsIntent: AppIntent {
    static var title: LocalizedStringResource = "Count Words"
    static var description = IntentDescription("Count the words in text using LinguaSyntax.")

    @Parameter(title: "Text")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Count words in \(\.$text)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let wordCount = text.wordCount
        return .result(value: wordCount, dialog: "Found \(wordCount) words.")
    }
}

enum PartsOfSpeechOutputFormat: String, AppEnum {
    case text, rtf

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Output Format"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .text: "Text",
        .rtf: "RTF"
    ]
}

struct ExportRTFIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Styled RTF"
    static var description = IntentDescription("Convert text into styled RTF data using LinguaSyntax.")

    @Parameter(title: "Text")
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Export styled RTF from \(\.$text)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let data = try Self.rtfData(for: text, theme: Settings().theme)
        let file = IntentFile(data: data, filename: "LinguaSyntax.rtf", type: .rtf)
        return .result(value: file, dialog: "Exported styled RTF.")
    }

    @MainActor
    static func rtfData(for text: String, theme: Theme) throws -> Data {
        let highlightedText = NSAttributedString(text.highlightSyntax(theme: theme))
        return try CounterViewController.rtfData(from: highlightedText, theme: theme)
    }
}

struct ExportPartsOfSpeechIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Parts of Speech"
    static var description = IntentDescription("Count parts of speech in text and export the result as text or styled RTF.")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Output Format", default: .text)
    var outputFormat: PartsOfSpeechOutputFormat

    static var parameterSummary: some ParameterSummary {
        Summary("Export parts of speech for \(\.$text) as \(\.$outputFormat)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let file = try Self.outputFile(for: text, outputFormat: outputFormat, theme: Settings().theme)
        return .result(value: file, dialog: "Exported parts of speech.")
    }

    @MainActor
    static func outputFile(for text: String, outputFormat: PartsOfSpeechOutputFormat, theme: Theme) throws -> IntentFile {
        switch outputFormat {
        case .text:
            let summary = String(text.partsOfSpeech(theme: theme).characters)
            return IntentFile(
                data: Data(summary.utf8),
                filename: "LinguaSyntax Parts of Speech.txt",
                type: .plainText
            )
        case .rtf:
            let summary = NSAttributedString(text.partsOfSpeech(theme: theme))
            let data = try CounterViewController.rtfData(from: summary, theme: theme)
            return IntentFile(
                data: data,
                filename: "LinguaSyntax Parts of Speech.rtf",
                type: .rtf
            )
        }
    }
}

struct LinguaSyntaxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ImportTextIntent(),
            phrases: [
                "Import text in \(.applicationName)",
                "Analyze text with \(.applicationName)"
            ],
            shortTitle: "Import Text",
            systemImageName: "text.viewfinder"
        )

        AppShortcut(
            intent: CountWordsIntent(),
            phrases: [
                "Count words with \(.applicationName)",
                "Count text in \(.applicationName)"
            ],
            shortTitle: "Count Words",
            systemImageName: "number"
        )

        AppShortcut(
            intent: ExportRTFIntent(),
            phrases: [
                "Export styled RTF with \(.applicationName)",
                "Create styled RTF with \(.applicationName)"
            ],
            shortTitle: "Export RTF",
            systemImageName: "doc.richtext"
        )

        AppShortcut(
            intent: ExportPartsOfSpeechIntent(),
            phrases: [
                "Export parts of speech with \(.applicationName)",
                "Count parts of speech with \(.applicationName)"
            ],
            shortTitle: "Parts of Speech",
            systemImageName: "list.bullet.rectangle"
        )
    }
}
