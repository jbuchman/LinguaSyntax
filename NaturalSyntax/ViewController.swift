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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        moreButton.menu = UIMenu(children: [
            UIMenu(options: [.displayInline, .displayAsPalette], children: [
                UIAction(subtitle: "Cut", image: UIImage(systemName: "scissors"), handler: textView.cut(_:)),
                UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), state: .off, handler: textView.copy(_:)),
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
        updateSyntaxHighlight()
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
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSyntaxHighlight()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateSyntaxHighlight()
    }
}
