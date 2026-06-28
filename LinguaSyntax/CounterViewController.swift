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
    private lazy var keyboardDismissButtonContainerView = makeKeyboardDismissButtonContainerView()
    private lazy var keyboardDismissSpacerView = makeKeyboardDismissSpacerView()
    private lazy var keyboardDismissButton = makeKeyboardDismissButton()
    let settings: Settings
    weak var sourceTextView: TextView?
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureKeyboardDismissButton()

        settings.$theme.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] theme in
            guard let self else {
                return
            }

            self.generateMenu(theme: theme)
            self.updateAppearance(theme: theme)
            self.contentUpdate(theme: theme)
        }).store(in: &cancellables)

        settings.$text.receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] text in
            guard let self else {
                return
            }

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

    func setKeyboardDismissButtonVisible(_ isVisible: Bool) {
        keyboardDismissButtonContainerView.isHidden = !isVisible
        keyboardDismissSpacerView.isHidden = !isVisible
    }

    private func configureKeyboardDismissButton() {
        guard let stackView = counterSpacerView.superview as? UIStackView,
              keyboardDismissButtonContainerView.superview == nil else {
            return
        }

        keyboardDismissButtonContainerView.addSubview(keyboardDismissButton)
        keyboardDismissButtonContainerView.isHidden = true
        keyboardDismissSpacerView.isHidden = true
        stackView.insertArrangedSubview(keyboardDismissButtonContainerView, at: 0)
        stackView.insertArrangedSubview(keyboardDismissSpacerView, at: 1)

        NSLayoutConstraint.activate([
            keyboardDismissButton.centerXAnchor.constraint(equalTo: keyboardDismissButtonContainerView.centerXAnchor),
            keyboardDismissButton.centerYAnchor.constraint(equalTo: keyboardDismissButtonContainerView.centerYAnchor),
            keyboardDismissButton.widthAnchor.constraint(equalToConstant: 44),
            keyboardDismissButton.heightAnchor.constraint(equalToConstant: 44),
            keyboardDismissButtonContainerView.widthAnchor.constraint(equalToConstant: 44),
            keyboardDismissSpacerView.widthAnchor.constraint(equalTo: counterSpacerView.widthAnchor)
        ])
    }

    private func makeKeyboardDismissButtonContainerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }

    private func makeKeyboardDismissSpacerView() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    private func makeKeyboardDismissButton() -> UIButton {
        var configuration: UIButton.Configuration
        if #available(iOS 26.0, *) {
            configuration = UIButton.Configuration.prominentClearGlass()
            configuration.image = UIImage(systemName: "keyboard.chevron.compact.down")
        } else {
            configuration = UIButton.Configuration.plain()
            configuration.baseForegroundColor = .secondaryLabel

            configuration.image = UIImage(systemName: "keyboard.chevron.compact.down")
        }

        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.resetFocus()
        })
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = String(localized: "Dismiss Keyboard")
        return button
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

    private func editCustomTheme() {
        if case .custom(let currentCustomTheme) = settings.theme {
            presentCustomThemeEditor(theme: currentCustomTheme)
        } else {
            confirmCustomThemeOverride(basedOn: settings.theme)
        }
    }

    private func confirmCustomThemeOverride(basedOn theme: Theme) {
        let alertController = UIAlertController(
            title: String(localized: "Override Custom Theme?"),
            message: String(localized: "Use \(theme.name) as the starting point for a new custom theme."),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alertController.addAction(UIAlertAction(title: String(localized: "Use \(theme.name)"), style: .default) { [weak self] _ in
            self?.presentCustomThemeEditor(theme: CustomTheme(basedOn: theme))
        })

        present(alertController, animated: true)
    }

    private func presentCustomThemeEditor(theme customTheme: CustomTheme) {
        let viewController = CustomThemeViewController(theme: customTheme) { [weak self] customTheme in
            self?.settings.theme = .custom(customTheme)
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }

    private func generateMenu(theme currentTheme: Theme) {
        let themes: [UIAction] = Theme.builtInThemes.map { theme in
            UIAction(title: theme.name, state: theme == currentTheme ? .on : .off) { [weak self] _ in
                self?.select(theme: theme)
            }
        }
        let customThemeAction = UIAction(title: String(localized: "Custom"), state: currentTheme.isCustom ? .on : .off) { [weak self] _ in
            self?.select(theme: .custom(Settings.loadCustomTheme()))
        }
        let editCustomThemeAction = UIAction(title: String(localized: "Edit Custom Theme"), image: UIImage(systemName: "paintpalette")) { [weak self] _ in
            self?.editCustomTheme()
        }

        moreButton.menu = UIMenu(children: [
            UIMenu(title: String(localized: "Theme"), children: themes + [customThemeAction, editCustomThemeAction]),
            UIMenu(options: [.displayInline], children: [
                UIAction(title: String(localized: "Cut All"), image: UIImage(systemName: "scissors")) { [weak self] _ in
                    self?.sourceTextView?.cutAll()
                },
                UIAction(title: String(localized: "Copy All"), image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                    self?.sourceTextView?.copyAll()
                },
                UIAction(title: String(localized: "Replace All"), image: UIImage(systemName: "document.on.clipboard")) { [weak self] _ in
                    self?.sourceTextView?.replaceAllWithPasteboardText()
                },
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: String(localized: "Select All"), image: UIImage(systemName: "selection.pin.in.out")) { [weak self] action in
                    self?.sourceTextView?.selectAll(action)
                },
            ]),
            UIMenu(options: .displayInline, children: [
                UIAction(title: String(localized: "Delete All"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    self?.sourceTextView?.deleteAll()
                },
            ])
        ])
    }
    
    func updateAppearance(theme: Theme? = nil, isMinimized: Bool? = nil) {
        let theme = theme ?? settings.theme

        overrideUserInterfaceStyle = theme.interfaceStyle
        partsOfSpeechTextView.overrideUserInterfaceStyle = theme.interfaceStyle
        partsOfSpeechTextView.backgroundColor = .clear
        partsOfSpeechTextView.typingAttributes = Theme.textAttributes(theme: theme)

        let updateViews = { [weak self] in
            guard let self else { return }
            let shouldHidePartsOfSpeech = isMinimized ?? (sheetPresentationController?.selectedDetentIdentifier == Constants.minimizedIdentifier)
            view.backgroundColor = theme.secondaryBackground(traitCollection: traitCollection)
            keyboardDismissButton.tintColor = .secondaryLabel
            partsOfSpeechTextView.isHidden = shouldHidePartsOfSpeech
        }

        if let sheetPresentationController {
            sheetPresentationController.animateChanges(updateViews)
        } else {
            updateViews()
        }
    }
}
