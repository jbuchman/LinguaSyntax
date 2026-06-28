//
//  TextImporter.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import Foundation

enum TextImporter {
    static let didImportTextNotification = Notification.Name("TextImporter.didImportTextNotification")
    static let importedTextUserInfoKey = "text"

    static func importText(_ text: String, shouldNotify: Bool = true) {
        UserDefaults.standard.set(text, forKey: Constants.textKey)

        guard shouldNotify else {
            return
        }

        NotificationCenter.default.post(
            name: didImportTextNotification,
            object: nil,
            userInfo: [importedTextUserInfoKey: text]
        )
    }

    @discardableResult
    static func importPendingSharedText() -> String? {
        if let text = pendingSharedTextFromFile() {
            importText(text)
            return text
        }

        guard let sharedDefaults = UserDefaults(suiteName: Constants.appGroupIdentifier),
              let text = sharedDefaults.string(forKey: Constants.pendingSharedTextKey),
              !text.isEmpty else {
            return nil
        }

        sharedDefaults.removeObject(forKey: Constants.pendingSharedTextKey)
        importText(text)
        return text
    }

    static func pendingSharedTextFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier)?
            .appendingPathComponent(Constants.pendingSharedTextFileName)
    }

    private static func pendingSharedTextFromFile() -> String? {
        guard let fileURL = pendingSharedTextFileURL(),
              let text = try? String(contentsOf: fileURL, encoding: .utf8),
              !text.isEmpty else {
            return nil
        }

        try? FileManager.default.removeItem(at: fileURL)
        return text
    }
}
