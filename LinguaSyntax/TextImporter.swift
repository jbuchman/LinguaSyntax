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
}
