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
    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        loadSharedText { [weak self] text in
            guard let self else { return }
            guard let text, let importURL = Self.importURL(for: text) else {
                extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }

            extensionContext?.open(importURL) { [weak self] _ in
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func loadSharedText(completion: @escaping (String?) -> Void) {
        var textFragments = [String]()
        if !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textFragments.append(contentText)
        }

        let itemProviders = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []

        guard !itemProviders.isEmpty else {
            completion(joinedText(from: textFragments))
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()

        for itemProvider in itemProviders {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.enter()
                itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                    if let text = Self.text(from: item) {
                        lock.lock()
                        textFragments.append(text)
                        lock.unlock()
                    }
                    group.leave()
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    if let text = Self.text(from: item) {
                        lock.lock()
                        textFragments.append(text)
                        lock.unlock()
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(self.joinedText(from: textFragments))
        }
    }

    private func joinedText(from textFragments: [String]) -> String? {
        let text = textFragments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

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

    private static func importURL(for text: String) -> URL? {
        var components = URLComponents()
        components.scheme = "linguasyntax"
        components.host = "import"
        components.queryItems = [URLQueryItem(name: "text", value: text)]
        return components.url
    }
}
