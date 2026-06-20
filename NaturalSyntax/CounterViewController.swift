//
//  CounterViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import NaturalLanguage

enum Constants {
    static let minimizedIdentifier = UISheetPresentationController.Detent.Identifier("minimized")
}

class CounterViewController: UIViewController {
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var partsOfSpeechTextView: UITextView!
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBackgroundColor()
    }
    
    func contentUpdate(string: String) {
        wordLabel.text = "\(string.wordCount)"
        characterLabel.text = "\(string.count)"
        partsOfSpeechTextView.attributedText = NSAttributedString(string.partsOfSpeech())
    }
    
    func updateBackgroundColor() {
        sheetPresentationController?.animateChanges { [weak self] in
            guard let self else {
                return
            }
            let baseTraits = traitCollection.modifyingTraits { mutableTraits in
                // Explicitly downgrade the sheet's elevation level to flat base
                mutableTraits.userInterfaceLevel = .base
            }

            view.backgroundColor = UIColor.secondarySystemBackground.resolvedColor(with: baseTraits)
            
            if sheetPresentationController?.selectedDetentIdentifier == Constants.minimizedIdentifier {
                partsOfSpeechTextView.isHidden = true
            } else {
                partsOfSpeechTextView.isHidden = false
            }
        }
    }
}

