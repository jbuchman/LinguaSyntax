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
    @IBOutlet weak var moreButton: MoreMenuButton!
    @IBOutlet weak var counterSpacerView: UIView!
    @IBOutlet weak var moreButtonContainerView: UIView!
    let settings: Settings
    weak var sourceTextView: TextView?
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { theme in
            self.generateMenu(theme: theme)
            self.updateAppearance(theme: theme)
            self.contentUpdate(theme: theme)
        }).store(in: &cancellables)

        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { text in
            self.contentUpdate(text: text)
        }).store(in: &cancellables)
    }
    
    init?(coder: NSCoder, settings: Settings, sourceTextView: TextView) {
        self.settings = settings
        self.sourceTextView = sourceTextView
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction private func resetFocus() {
        sourceTextView?.resignFirstResponder()
    }
    
    private func contentUpdate(text: String? = nil, theme: Theme? = nil) {
        let text = text ?? settings.text
        let theme = theme ?? settings.theme
        wordLabel.text = "\(text.wordCount)"
        characterLabel.text = "\(text.count)"
        partsOfSpeechTextView.attributedText = NSAttributedString(text.partsOfSpeech(theme: theme))
    }

    private func select(theme: Theme) {
        settings.theme = theme
    }

    private func generateMenu(theme currentTheme: Theme) {
        let themes: [UIAction] = Theme.allCases.map { theme in
            UIAction(title: theme.name, state: theme == currentTheme ? .on : .off) { [weak self] _ in
                self?.select(theme: theme)
            }
        }

        moreButton.menu = UIMenu(children: [
            UIMenu(title: "Theme", children: themes),
            UIMenu(options: [.displayInline], children: [
                UIAction(title: "Cut All", image: UIImage(systemName: "scissors")) { [weak self] _ in
                    self?.sourceTextView?.cutAll()
                },
                UIAction(title: "Copy All", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                    self?.sourceTextView?.copyAll()
                },
                UIAction(title: "Replace All", image: UIImage(systemName: "document.on.clipboard")) { [weak self] _ in
                    self?.sourceTextView?.replaceAllWithPasteboardText()
                },
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Select All", image: UIImage(systemName: "selection.pin.in.out")) { [weak self] action in
                    self?.sourceTextView?.selectAll(action)
                },
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Delete All", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    self?.sourceTextView?.deleteAll()
                },
            ])
        ])
    }
    
    func updateAppearance(theme: Theme? = nil) {
        let theme = theme ?? settings.theme

        overrideUserInterfaceStyle = theme.interfaceStyle
        partsOfSpeechTextView.overrideUserInterfaceStyle = theme.interfaceStyle
        partsOfSpeechTextView.backgroundColor = .clear
        partsOfSpeechTextView.typingAttributes = Theme.textAttributes(theme: theme)

        let updateViews = { [weak self] in
            guard let self else { return }
            view.backgroundColor = theme.secondaryBackground(traitCollection: traitCollection)
            partsOfSpeechTextView.isHidden = sheetPresentationController?.selectedDetentIdentifier == Constants.minimizedIdentifier
        }

        if let sheetPresentationController {
            sheetPresentationController.animateChanges(updateViews)
        } else {
            updateViews()
        }
    }
}
