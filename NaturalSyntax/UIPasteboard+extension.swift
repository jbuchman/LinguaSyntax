//
//  UIPasteboard+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import UniformTypeIdentifiers // Available iOS 14+ for UTType identifiers

extension UIPasteboard {
    /// Scans the pasteboard for any available plain text format (UTF-8 data, plain text strings, or multi-item blocks)
    /// and flattens them into a clean array of strings.
    var allPlainText: [String] {
        var extractedStrings: [String] = []
        
        // Target Identifiers
        let utf8Key = UTType.utf8PlainText.identifier // "public.utf8-plain-text"
        let plainKey = UTType.plainText.identifier     // "public.plain-text"
        
        // Approach 1: Check multi-item clipboard arrays (iOS 16+ non-contiguous ranges support)
        if self.items.count > 0 {
            for item in self.items {
                // Try reading a raw UTF-8 binary stream payload first
                if let utf8Data = item[utf8Key] as? Data,
                   let decodedString = String(data: utf8Data, encoding: .utf8) {
                    extractedStrings.append(decodedString)
                    continue
                }
                
                // Fall back to standard string type identifiers
                if let plainString = item[plainKey] as? String {
                    extractedStrings.append(plainString)
                    continue
                }
                
                // Final generic string dictionary casting safety check
                if let genericString = item.values.first as? String {
                    extractedStrings.append(genericString)
                }
            }
        }
        
        // Approach 2: If the multi-item array yields nothing, look at standard top-level properties
        if extractedStrings.isEmpty {
            // Check top-level UTF-8 data binary payloads explicitly
            if self.contains(pasteboardTypes: [utf8Key]),
               let data = self.data(forPasteboardType: utf8Key),
               let decoded = String(data: data, encoding: .utf8) {
                extractedStrings.append(decoded)
            } 
            // Fall back to standard strings or single selection elements
            else if let singleString = self.string {
                extractedStrings.append(singleString)
            } 
            // Fall back to bulk arrays of text blocks
            else if let multiStrings = self.strings {
                extractedStrings.append(contentsOf: multiStrings)
            }
        }
        
        // Return accumulated non-empty string results
        return extractedStrings.filter { !$0.isEmpty }
    }
}
