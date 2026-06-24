//
//  LinguaSyntaxShortcuts.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import AppIntents
import Foundation

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
    }
}
