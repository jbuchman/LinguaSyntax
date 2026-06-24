//
//  TextView.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import UniformTypeIdentifiers

enum Scope {
    case all, selectedRange, selectedText, none
}

class TextView: UITextView {
    var pasteboardTextProvider: (() -> [String])?

    override func cut(_ sender: Any?) {
        let scope = scope(sender)
        guard scope != .none else {
            return
        }

        copyAttributedText(for: scope)
        if deleteText(for: scope) {
            delegate?.textViewDidChange?(self)
        }
    }
    
    override func copy(_ sender: Any?) {
        let scope = scope(sender)
        copyAttributedText(for: scope)
    }
    
    override func paste(_ sender: Any?) {
        pasteAttributedText()
    }
        
    override func delete(_ sender: Any?) {
        let scope = scope(sender)
        guard deleteText(for: scope) else {
            return
        }

        delegate?.textViewDidChange?(self)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.select(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    func scope(_ sender: Any?) -> Scope {
        if #available(iOS 26.0, *) {
            if selectedRanges.contains(where: { $0.length > 0 }) {
                return .selectedText
            }
        } else {
            if selectedRange.length > 0 {
                return .selectedText
            }
        }
        return .none
    }

    func cutAll() {
        copyAttributedText(for: .all)
        if deleteText(for: .all) {
            delegate?.textViewDidChange?(self)
        }
    }

    func copyAll() {
        copyAttributedText(for: .all)
    }

    func replaceAllWithPasteboardText() {
        pasteAttributedText(replacing: .all)
    }

    func deleteAll() {
        if deleteText(for: .all) {
            delegate?.textViewDidChange?(self)
        }
    }

    /// Scans the pasteboard for any available plain text format (UTF-8 data, plain text strings, or multi-item blocks)
    /// and flattens them into a clean array of strings.
    static func defaultPasteboardText() -> [String] {
        var extractedStrings: [String] = []
        
        // Target Identifiers
        let utf8Key = UTType.utf8PlainText.identifier // "public.utf8-plain-text"
        let plainKey = UTType.plainText.identifier     // "public.plain-text"
        
        // Approach 1: Check multi-item clipboard arrays (iOS 16+ non-contiguous ranges support)
        if UIPasteboard.general.items.count > 0 {
            for item in UIPasteboard.general.items {
                // Priority 1: Explicitly check for raw UTF-8 binary plain text streams first
                if let utf8Data = item[utf8Key] as? Data,
                   let decodedString = String(data: utf8Data, encoding: .utf8) {
                    extractedStrings.append(decodedString)
                    continue
                }
                
                // Priority 2: Fall back strictly to standard unstyled plain text identifiers
                if let plainString = item[plainKey] as? String {
                    extractedStrings.append(plainString)
                    continue
                }
            }
        }
        
        // Approach 2: If the multi-item array yields nothing, look at standard top-level properties
        if extractedStrings.isEmpty {
            // Check top-level UTF-8 data binary payloads explicitly
            if UIPasteboard.general.contains(pasteboardTypes: [utf8Key]),
               let data = UIPasteboard.general.data(forPasteboardType: utf8Key),
               let decoded = String(data: data, encoding: .utf8) {
                extractedStrings.append(decoded)
            }
            // Fall back to standard strings or single selection elements
            else if let singleString = UIPasteboard.general.string {
                extractedStrings.append(singleString)
            }
            // Fall back to bulk arrays of text blocks
            else if let multiStrings = UIPasteboard.general.strings {
                extractedStrings.append(contentsOf: multiStrings)
            }
        }
        
        // Return accumulated non-empty string results
        return extractedStrings.filter { !$0.isEmpty }
    }

    func pasteAttributedText(replacing scope: Scope = .selectedRange) {
        let pasteboardText = pasteboardTextProvider?() ?? Self.defaultPasteboardText()
        let parsedAttributedStrings: [NSAttributedString] = pasteboardText.map { NSAttributedString(string: $0, attributes: [.font: Theme.dark.font]) }
        
        guard !parsedAttributedStrings.isEmpty else { return }
        
        // Flatten non-contiguous nodes into a continuous layout stream using a newline divider
        let finalAttributedCombination = NSMutableAttributedString()
        let newline = NSAttributedString(string: "\n")
        
        for (index, attrString) in parsedAttributedStrings.enumerated() {
            finalAttributedCombination.append(attrString)
            if index < parsedAttributedStrings.count - 1 {
                finalAttributedCombination.append(newline)
            }
        }
        
        let replacementRange: NSRange
        switch scope {
        case .all:
            replacementRange = NSRange(location: 0, length: attributedText.length)

        case .selectedRange, .selectedText:
            replacementRange = selectedRange

        case .none:
            return
        }

        textStorage.replaceCharacters(in: replacementRange, with: finalAttributedCombination)
        
        // Re-collapse cursor anchor target cleanly right after inserted payload length
        let targetEndLocation = replacementRange.location + finalAttributedCombination.length
        selectedRange = NSRange(location: targetEndLocation, length: 0)
        delegate?.textViewDidChange?(self)
    }
    
    @discardableResult
    func deleteText(for scope: Scope) -> Bool {
        switch scope {
        case .all:
            guard attributedText.length > 0 else {
                return false
            }
            textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: "")
            return true
            
        case .selectedText:
            if #available(iOS 26.0, *) {
                // CRITICAL: Deleting from the bottom up protects index locations from shifting
                let sortedRanges = selectedRanges.sorted { $0.location > $1.location }
                
                var didDelete = false
                for range in sortedRanges {
                    guard range.length > 0 else { continue }
                    textStorage.replaceCharacters(in: range, with: "")
                    didDelete = true
                }
                return didDelete
            } else {
                // Fallback for iOS 18
                let currentSelectedNSRange = selectedRange
                if currentSelectedNSRange.length > 0 {
                    textStorage.replaceCharacters(in: currentSelectedNSRange, with: "")
                    return true
                }
                return false
            }

        case .selectedRange, .none:
            return false
        }
    }
        
    func copyAttributedText(for scope: Scope) {
        var pasteboardItems: [[String: Any]] = []
        let rtfKey = UTType.rtf.identifier
        let plainKey = UTType.plainText.identifier
        
        switch scope {
        case .all:
            guard attributedText.length > 0 else { return }
            if let rtfData = rtfData(from: NSRange(location: 0, length: attributedText.length)) {
                pasteboardItems.append([rtfKey: rtfData, plainKey: attributedText.string])
            }
            
        case .selectedText:
            if #available(iOS 26.0, *) {
                // Collect separate rich text item slices for non-contiguous highlights
                for nsRange in selectedRanges {
                    guard nsRange.length > 0 else { continue }
                    let subString = attributedText.attributedSubstring(from: nsRange)
                    
                    if let rtfData = rtfData(from: nsRange) {
                        pasteboardItems.append([rtfKey: rtfData, plainKey: subString.string])
                    }
                }
            } else {
                // Fallback for iOS 18
                let nsRange = selectedRange
                if nsRange.length > 0 {
                    let subString = attributedText.attributedSubstring(from: nsRange)
                    if let rtfData = rtfData(from: nsRange) {
                        pasteboardItems.append([rtfKey: rtfData, plainKey: subString.string])
                    }
                }
            }

        case .selectedRange, .none:
            return
        }
        
        if !pasteboardItems.isEmpty {
            UIPasteboard.general.items = pasteboardItems
        }
    }
    
    // MARK: - Private Helpers
    private func textRange(fromNSRange nsRange: NSRange) -> UITextRange? {
        guard let start = position(from: beginningOfDocument, offset: nsRange.location),
              let end = position(from: start, offset: nsRange.length) else { return nil }
        return textRange(from: start, to: end)
    }
    
    private func rtfData(from range: NSRange) -> Data? {
        return try? attributedText.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
