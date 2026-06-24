//
//  MoreMenuButton.swift
//  LinguaSyntax
//
//  Created by Jeremy Buchman on 6/24/26.
//

import UIKit

final class MoreMenuButton: UIButton {
    override func awakeFromNib() {
        super.awakeFromNib()

        showsMenuAsPrimaryAction = true
        accessibilityLabel = String(localized: "More")

        if #available(iOS 26.0, *) {
            var configuration = UIButton.Configuration.prominentClearGlass()
            configuration.image = UIImage(systemName: "ellipsis")
            self.configuration = configuration
        } else {
            setImage(UIImage(systemName: "ellipsis"), for: .normal)
        }
    }
}
