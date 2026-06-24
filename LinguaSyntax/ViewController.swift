//
//  ViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import Combine
import NaturalLanguage

class ViewController: UIViewController {
    @IBOutlet weak var textView: TextView! { didSet {
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
    }}
    @IBOutlet weak var placeholderLabel: UILabel!
    let settings = Settings()
    var cancellables: Set<AnyCancellable> = []

    lazy var counterViewController: CounterViewController? = {
        storyboard?.instantiateViewController(identifier: "counter") { coder in
            CounterViewController(coder: coder, settings: self.settings, sourceTextView: self.textView)
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetFocus)))
        
        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] text in
            guard let self else {
                return
            }

            guard self.textView.text != text else {
                return
            }

            self.textView.text = text
            self.updateSyntaxHighlight()
        }).store(in: &cancellables)
        
        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] theme in
            guard let self else {
                return
            }

            self.updateSyntaxHighlight(theme: theme)
        }).store(in: &cancellables)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let counterViewController = counterViewController, presentedViewController == nil else { return }
        
        // 1. Configure the View Controller layout parameters PRIOR to presentation
        counterViewController.modalPresentationStyle = .pageSheet
        counterViewController.isModalInPresentation = true // CRITICAL FIX: Blocks pull-down dismiss gestures!
        
        // 2. Configure the sheet presentation layer once active
        if let sheet = counterViewController.sheetPresentationController {
            sheet.delegate = self
            
            let minimizedDetent = UISheetPresentationController.Detent.custom(identifier: Constants.minimizedIdentifier) { _ in
                return 70 // Apple maps minimized height boundary line
            }
            
            sheet.detents = [minimizedDetent, .medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .large // Keeps your text view scrolling interactive
            sheet.prefersGrabberVisible = true
        }

        present(counterViewController, animated: true)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        textView.canPerformAction(action, withSender: sender)
    }
    
    @objc func resetFocus() {
        textView.resignFirstResponder()
    }
    
    private func updateSyntaxHighlight(theme: Theme? = nil) {
        let theme = theme ?? settings.theme
        if !textView.isFirstResponder, textView.text.isEmpty, let string = placeholderLabel.text {
            placeholderLabel.attributedText = NSAttributedString(string: string, attributes: [
                .font: theme.font,
                .foregroundColor: UIColor.secondaryLabel
            ])
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
            applySyntaxHighlight(theme: theme)
        }
        view.backgroundColor = theme.backgroundColor
        overrideUserInterfaceStyle = theme.interfaceStyle
        textView.overrideUserInterfaceStyle = theme.interfaceStyle
        navigationController?.navigationBar.overrideUserInterfaceStyle = theme.interfaceStyle
        counterViewController?.overrideUserInterfaceStyle = theme.interfaceStyle
    }

    private func applySyntaxHighlight(theme: Theme) {
        textView.typingAttributes = Theme.textAttributes(theme: theme)

        guard textView.markedTextRange == nil else {
            return
        }

        let string = textView.text ?? ""
        guard !string.isEmpty else {
            return
        }

        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.textStorage.beginEditing()
        textView.textStorage.removeAttribute(.underlineStyle, range: fullRange)
        textView.textStorage.addAttributes(Theme.textAttributes(theme: theme), range: fullRange)

        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = string
        tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: String.syntaxTaggerOptions) { tag, tokenRange in
            guard let tag else {
                return true
            }

            textView.textStorage.addAttributes(tag.textAttributes(theme: theme), range: NSRange(tokenRange, in: string))
            return true
        }

        textView.textStorage.endEditing()
    }
}

// MARK: - UITextViewDelegate
extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSyntaxHighlight()
        settings.text = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate & UISheetPresentationControllerDelegate
extension ViewController: UIAdaptivePresentationControllerDelegate, UISheetPresentationControllerDelegate {
    
    // Fallback handler if isModalInPresentation flags face boundary constraints
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    // Enforces Apple Maps bounce-back mechanism when an illegal downward swipe occurs
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if let sheet = counterViewController?.sheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = Constants.minimizedIdentifier
            }
        }
    }
    
    // Triggers automatically the exact instant the sheet successfully settles into a detent position
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        counterViewController?.updateAppearance()
    }
}
