//
//  CounterViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import NaturalLanguage
import Combine

class CounterViewController: UIViewController {
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var partsOfSpeechTextView: UITextView!
    let settings: Settings
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { theme in
            self.updateBackgroundColor(theme: theme)
            self.contentUpdate(theme: theme)
        }).store(in: &cancellables)

        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { text in
            self.contentUpdate(text: text)
        }).store(in: &cancellables)
    }
    
    init?(coder: NSCoder, settings: Settings) {
        self.settings = settings
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func contentUpdate(text: String? = nil, theme: Theme? = nil) {
        let text = text ?? settings.text
        let theme = theme ?? settings.theme
        wordLabel.text = "\(text.wordCount)"
        characterLabel.text = "\(text.count)"
        partsOfSpeechTextView.attributedText = NSAttributedString(text.partsOfSpeech(theme: theme))
    }
    
    func updateBackgroundColor(theme: Theme? = nil) {
        let theme = theme ?? settings.theme
        sheetPresentationController?.animateChanges { [weak self] in
            guard let self else {
                return
            }

            view.backgroundColor = theme.secondaryBackground(traitCollection: traitCollection)
            if sheetPresentationController?.selectedDetentIdentifier == Constants.minimizedIdentifier {
                partsOfSpeechTextView.isHidden = true
            } else {
                partsOfSpeechTextView.isHidden = false
            }
        }
    }
}

