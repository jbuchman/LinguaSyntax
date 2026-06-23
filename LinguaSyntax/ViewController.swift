//
//  ViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet weak var textView: TextView! { didSet {
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
    }}
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var placeholderLabel: UILabel!
    let settings = Settings()
    var cancellables: Set<AnyCancellable> = []

    lazy var counterViewController: CounterViewController? = {
        storyboard?.instantiateViewController(identifier: "counter") { coder in
            CounterViewController(coder: coder, settings: self.settings)
        }
    }()

    private func select(theme: Theme) {
        settings.theme = theme
    }
    
    private func generateMenu(theme currentTheme: Theme) {
        let themes: [UIAction] = Theme.allCases.map { theme in
            UIAction(title: theme.name, state: theme == currentTheme ? .on : .off, handler: { _ in self.select(theme: theme)
            })
        }
        
        moreButton.menu = UIMenu(children: [
            UIMenu(title: "Theme", children: themes),
            UIMenu(options: [.displayInline], children: [
                UIAction(title: "Cut", image: UIImage(systemName: "scissors"), handler: textView.cut(_:)),
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), handler: textView.copy(_:)),
                UIAction(title: "Paste", image: UIImage(systemName: "document.on.clipboard"), handler: textView.paste(_:)),
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Select All", image: UIImage(systemName: "selection.pin.in.out"), handler: textView.selectAll(_:)),
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive, handler: textView.delete(_:)),
            ])
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetFocus)))
        
        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { text in
            self.textView.text = text
        }).store(in: &cancellables)
        
        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { theme in
            self.generateMenu(theme: theme)
            self.updateSyntaxHighlight(theme: theme)
        }).store(in: &cancellables)
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let counterViewController = counterViewController, counterViewController.presentingViewController == nil else { return }
        
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
                .foregroundColor: Theme.dark.foregroundColor
            ])
            placeholderLabel.isHidden = false
        } else {
            textView.attributedText = NSAttributedString(textView.text.highlightSyntax(theme: theme))
            placeholderLabel.isHidden = true
        }
        view.backgroundColor = theme.backgroundColor
        overrideUserInterfaceStyle = theme.interfaceStyle
        textView.overrideUserInterfaceStyle = theme.interfaceStyle
        navigationController?.navigationBar.overrideUserInterfaceStyle = theme.interfaceStyle
        counterViewController?.overrideUserInterfaceStyle = theme.interfaceStyle
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
        counterViewController?.updateBackgroundColor()
    }
}
