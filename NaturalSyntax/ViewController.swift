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
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        textView.canPerformAction(action, withSender: sender)
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        print("textViewDidChange")
    }
}
