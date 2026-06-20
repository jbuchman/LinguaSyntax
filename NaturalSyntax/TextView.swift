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
    
    override func selectAll(_ sender: Any?) {
        if #available(iOS 26.0, *) {
            selectedRanges = [NSRange(location: 0, length: attributedText.length)]
        } else {
            selectedRange = NSRange(location: 0, length: attributedText.length)
        }
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

    func pasteAttributedText() {
        let plainKey = UTType.plainText.identifier
        let plainUtf8Key = UTType.utf8PlainText.identifier
        let items = UIPasteboard.general.items
        
        var parsedStrings: [String] = UIPasteboard.general.allPlainText
        var parsedAttributedStrings: [NSAttributedString] = parsedStrings.map { NSAttributedString(string: $0, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]) }
        
        guard !parsedAttributedStrings.isEmpty else { return }
        
        // Flatten non-contiguous nodes into a continuous layout stream using a newline divider
        let finalAttributedCombination = NSMutableAttributedString()
        let newline = NSAttributedString(string: "\n")
        
        for (index, attrString) in parsedAttributedStrings.enumerated() {
            finalAttributedCombination.append(attrString)
            if index < parsedStrings.count - 1 {
                finalAttributedCombination.append(newline)
            }
        }
        
        // Safely splice the reconstructed string back into active editor cursor coordinates
        let currentSelectedNSRange = self.selectedRange
        let currentMutable = NSMutableAttributedString(attributedString: self.attributedText)
        
        currentMutable.replaceCharacters(in: currentSelectedNSRange, with: finalAttributedCombination)
        self.attributedText = currentMutable
        
        // Re-collapse cursor anchor target cleanly right after inserted payload length
        let targetEndLocation = currentSelectedNSRange.location + finalAttributedCombination.length
        self.selectedRange = NSRange(location: targetEndLocation, length: 0)
    }
    
    func deleteText(for scope: Scope) {
        switch scope {
        case .all:
            self.attributedText = NSAttributedString()
            
        case .selection:
            if #available(iOS 26.0, *) {
                // CRITICAL: Deleting from the bottom up protects index locations from shifting
                let sortedRanges = self.selectedRanges.sorted { $0.location > $1.location }
                
                let currentMutable = NSMutableAttributedString(attributedString: self.attributedText)
                for range in sortedRanges {
                    guard range.length > 0 else { continue }
                    currentMutable.replaceCharacters(in: range, with: "")
                }
                self.attributedText = currentMutable
            } else {
                // Fallback for iOS 18
                let currentSelectedNSRange = self.selectedRange
                if currentSelectedNSRange.length > 0 {
                    let currentMutable = NSMutableAttributedString(attributedString: self.attributedText)
                    currentMutable.replaceCharacters(in: currentSelectedNSRange, with: "")
                    self.attributedText = currentMutable
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
            guard self.attributedText.length > 0 else { return }
            if let rtfData = self.rtfData(from: NSRange(location: 0, length: self.attributedText.length)) {
                pasteboardItems.append([rtfKey: rtfData, plainKey: self.attributedText.string])
            }
            
        case .selection:
            if #available(iOS 26.0, *) {
                // Collect separate rich text item slices for non-contiguous highlights
                for nsRange in self.selectedRanges {
                    guard nsRange.length > 0 else { continue }
                    let subString = self.attributedText.attributedSubstring(from: nsRange)
                    
                    if let rtfData = self.rtfData(from: nsRange) {
                        pasteboardItems.append([rtfKey: rtfData, plainKey: subString.string])
                    }
                }
            } else {
                // Fallback for iOS 18
                let nsRange = self.selectedRange
                if nsRange.length > 0 {
                    let subString = self.attributedText.attributedSubstring(from: nsRange)
                    if let rtfData = self.rtfData(from: nsRange) {
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
        guard let start = self.position(from: self.beginningOfDocument, offset: nsRange.location),
              let end = self.position(from: start, offset: nsRange.length) else { return nil }
        return self.textRange(from: start, to: end)
    }
    
    private func rtfData(from range: NSRange) -> Data? {
        return try? self.attributedText.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
