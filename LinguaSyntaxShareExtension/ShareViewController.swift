//
//  ShareViewController.swift
//  LinguaSyntaxShareExtension
//
//  Created by Jeremy Buchman on 6/24/26.
//

import Social
import UIKit
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    private enum SharedImport {
        static let appGroupIdentifier = "group.mobi.buchman.linguasyntax"
        static let pendingSharedTextFileName = "pending-shared-text.txt"
        static let importURLScheme = "linguasyntax"
        static let importURLHost = "import"
    }

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        Task {
            let text = await loadSharedText()
            
            guard let text else {
                presentImportFailure(message: String(localized: "LinguaSyntax could not find text to import."))
                return
            }
            
            guard Self.savePendingSharedText(text), let importURL = Self.importURL() else {
                presentImportFailure(message: String(localized: "LinguaSyntax could not save text for import. Make sure the app and share extension both have the LinguaSyntax App Group enabled."))
                return
            }
                        
            if let extensionContext, await extensionContext.open(importURL) || self.openURLThroughResponderChain(importURL) {
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            } else {
                self.presentImportFailure(message: String(localized: "LinguaSyntax could not open the app to import this text."))
            }
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func loadSharedText() async -> String? {
        var textFragments = [String]()
        if !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textFragments.append(contentText)
        }

        let itemProviders = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []

        guard !itemProviders.isEmpty else {
            return joinedText(from: textFragments)
        }
        
        for itemProvider in itemProviders {
            if let typeIdentifier = Self.supportedTypeIdentifier(for: itemProvider) {
                do {
                    let string: String? = try await withCheckedThrowingContinuation { continuation in
                        itemProvider.loadItem(forTypeIdentifier: typeIdentifier) { item, error in
                            if let error {
                                continuation.resume(throwing: error)
                                return
                            }
                            continuation.resume(returning: item?.string)
                        }
                    }
                    if let string {
                        textFragments.append(string)
                    }
                } catch {
                    print("Failed to load item provider for \(typeIdentifier): \(error)")
                }
            }
        }

        return joinedText(from: textFragments)
    }

    private func joinedText(from textFragments: [String]) -> String? {
        var seenFragments = Set<String>()
        let uniqueFragments = textFragments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seenFragments.insert($0).inserted }

        let text = uniqueFragments.joined(separator: "\n\n")
        return text.isEmpty ? nil : text
    }

    private static func text(from item: NSSecureCoding?) -> String? {
        switch item {
        case let string as String:
            return string
        case let attributedString as NSAttributedString:
            return attributedString.string
        case let url as URL:
            return url.absoluteString
        case let data as Data:
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }

    private static func supportedTypeIdentifier(for itemProvider: NSItemProvider) -> String? {
        [
            UTType.plainText.identifier,
            UTType.utf8PlainText.identifier,
            UTType.text.identifier,
            UTType.url.identifier
        ].first { itemProvider.hasItemConformingToTypeIdentifier($0) }
    }

    private static func savePendingSharedText(_ text: String) -> Bool {
        guard let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedImport.appGroupIdentifier)?
            .appendingPathComponent(SharedImport.pendingSharedTextFileName) else {
            return false
        }

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private static func importURL() -> URL? {
        var components = URLComponents()
        components.scheme = SharedImport.importURLScheme
        components.host = SharedImport.importURLHost
        return components.url
    }

    @discardableResult
    private func openURLThroughResponderChain(_ url: URL) -> Bool {
        let selector = NSSelectorFromString("openURL:")
        var responder: UIResponder? = self

        while let currentResponder = responder {
            if currentResponder.responds(to: selector) {
                currentResponder.perform(selector, with: url)
                return true
            }

            responder = currentResponder.next
        }

        return false
    }

    private func presentImportFailure(message: String) {
        let alertController = UIAlertController(
            title: String(localized: "Import Failed"),
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: String(localized: "OK"), style: .default))
        present(alertController, animated: true)
    }
}

extension NSSecureCoding {
    var string: String? {
        switch self {
        case let string as String:
            return string
        case let attributedString as NSAttributedString:
            return attributedString.string
        case let url as URL:
            return url.absoluteString
        case let data as Data:
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }
}
