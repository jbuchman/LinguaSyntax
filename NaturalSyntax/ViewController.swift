//
//  ViewController.swift
//  NaturalSyntax
//
//  Created by Jeremy Buchman on 6/20/26.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textView: TextView!
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBOutlet weak var placeholderLabel: UILabel!
        
    lazy var counterViewController: CounterViewController? = {
        storyboard?.instantiateViewController(identifier: "counter")
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        
        // Setup UIBarButton pop-up menu interactions safely utilizing text view responders
        moreButton.menu = UIMenu(children: [
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

        navigationController?.navigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resetFocus)))
        
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.text = UserDefaults.standard.string(forKey: "text")
        updateSyntaxHighlight()
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
        counterViewController.contentUpdate(string: textView.text)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        textView.canPerformAction(action, withSender: sender)
    }
    
    @objc func resetFocus() {
        textView.resignFirstResponder()
    }
    
    func updateSyntaxHighlight() {
        if !textView.isFirstResponder, textView.text.isEmpty, let string = placeholderLabel.text {
            placeholderLabel.attributedText = NSAttributedString(string: string, attributes: [
                .font: Theme.dark.font,
                .foregroundColor: Theme.dark.foregroundColor
            ])
            placeholderLabel.isHidden = false
        } else {
            textView.attributedText = NSAttributedString(textView.text.highlightSyntax())
            placeholderLabel.isHidden = true
        }
        view.backgroundColor = Theme.dark.backgroundColor
        overrideUserInterfaceStyle = Theme.dark.interfaceStyle
        textView.overrideUserInterfaceStyle = Theme.dark.interfaceStyle
        navigationController?.navigationBar.overrideUserInterfaceStyle = Theme.dark.interfaceStyle
        counterViewController?.overrideUserInterfaceStyle = Theme.dark.interfaceStyle
    }
}

// MARK: - UITextViewDelegate
extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSyntaxHighlight()
        counterViewController?.contentUpdate(string: textView.text)
        UserDefaults.standard.set(textView.text, forKey: "text")
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
