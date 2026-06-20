//
//  UIFont+extension.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//


import UIKit

extension UIFont {
    var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    func with(traits:UIFontDescriptor.SymbolicTraits...) -> UIFont {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
    
    func boldItalic() -> UIFont {
        return with(traits: .traitBold, .traitItalic)
    }
    
    func bold() -> UIFont {
        return with(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return with(traits: .traitItalic)
    }
    
}
