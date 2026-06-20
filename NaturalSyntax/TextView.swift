//
//  TextView.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import UniformTypeIdentifiers

enum Scope {
    case all, selection
}

class TextView: UITextView {
    override func cut(_ sender: Any?) {
        let scope = scope(sender)
        copyAttributedText(for: scope)
        deleteText(for: scope)
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
        deleteText(for: scope)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.select(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    func scope(_ sender: Any?) -> Scope {
        if sender is UIAction {
            return .all
        }
        if #available(iOS 26.0, *) {
            if selectedRanges.isEmpty {
                return .all
            }
        } else {
            if selectedRange.length == 0 {
                return .all
            }
        }
        return .selection
    }

    /// Scans the pasteboard for any available plain text format (UTF-8 data, plain text strings, or multi-item blocks)
    /// and flattens them into a clean array of strings.
    var allPasteboardText: [String] {
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

    func pasteAttributedText() {
        let parsedAttributedStrings: [NSAttributedString] = allPasteboardText.map { NSAttributedString(string: $0, attributes: [.font: Theme.dark.font]) }
        
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
        
        // Safely splice the reconstructed string back into active editor cursor coordinates
        let currentSelectedNSRange = selectedRange
        let currentMutable = NSMutableAttributedString(attributedString: attributedText)
        
        currentMutable.replaceCharacters(in: currentSelectedNSRange, with: finalAttributedCombination)
        attributedText = currentMutable
        
        // Re-collapse cursor anchor target cleanly right after inserted payload length
        let targetEndLocation = currentSelectedNSRange.location + finalAttributedCombination.length
        selectedRange = NSRange(location: targetEndLocation, length: 0)
        delegate?.textViewDidChange?(self)
    }
    
    func deleteText(for scope: Scope) {
        switch scope {
        case .all:
            attributedText = NSAttributedString()
            
        case .selection:
            if #available(iOS 26.0, *) {
                // CRITICAL: Deleting from the bottom up protects index locations from shifting
                let sortedRanges = selectedRanges.sorted { $0.location > $1.location }
                
                let currentMutable = NSMutableAttributedString(attributedString: attributedText)
                for range in sortedRanges {
                    guard range.length > 0 else { continue }
                    currentMutable.replaceCharacters(in: range, with: "")
                }
                attributedText = currentMutable
            } else {
                // Fallback for iOS 18
                let currentSelectedNSRange = selectedRange
                if currentSelectedNSRange.length > 0 {
                    let currentMutable = NSMutableAttributedString(attributedString: attributedText)
                    currentMutable.replaceCharacters(in: currentSelectedNSRange, with: "")
                    attributedText = currentMutable
                }
            }
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
            
        case .selection:
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
