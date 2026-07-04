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
    private var keyboardOverlapHeight: CGFloat = 0

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

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.keyboardFrameWillChange(notification)
            }
            .store(in: &cancellables)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let counterViewController = counterViewController, presentedViewController == nil else { return }
        
        // 1. Configure the View Controller layout parameters PRIOR to presentation
        counterViewController.modalPresentationStyle = .pageSheet
        counterViewController.preferredContentSize = CGSize(
            width: Self.preferredCounterSheetWidth(containerWidth: view.bounds.width),
            height: 0
        )
        counterViewController.isModalInPresentation = true // CRITICAL FIX: Blocks pull-down dismiss gestures!
        
        configureCounterSheet()

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
        tagger.setLanguageHint(textView.textInputMode?.naturalLanguageHint, for: string)
        tagger.enumerateTags(in: string.startIndex..<string.endIndex, unit: .word, scheme: .nameTypeOrLexicalClass, options: String.syntaxTaggerOptions) { tag, tokenRange in
            guard let tag else {
                return true
            }

            textView.textStorage.addAttributes(tag.textAttributes(theme: theme), range: NSRange(tokenRange, in: string))
            return true
        }

        textView.textStorage.endEditing()
    }

    private func keyboardFrameWillChange(_ notification: Notification) {
        keyboardOverlapHeight = keyboardOverlap(from: notification)
        let isKeyboardVisible = keyboardOverlapHeight > 0
        counterViewController?.setKeyboardDismissButtonVisible(isKeyboardVisible)
        configureCounterSheet(
            animated: true,
            selectedDetentIdentifier: isKeyboardVisible ? Constants.minimizedIdentifier : nil
        )
    }

    private func keyboardOverlap(from notification: Notification) -> CGFloat {
        guard notification.name != UIResponder.keyboardWillHideNotification,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let window = view.window else {
            return 0
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: window.screen.coordinateSpace)
        return max(0, view.bounds.maxY - keyboardFrameInView.minY)
    }

    private func configureCounterSheet(
        animated: Bool = false,
        selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = nil
    ) {
        guard let sheet = counterViewController?.sheetPresentationController else {
            return
        }

        let updateSheet = {
            self.counterViewController?.preferredContentSize = CGSize(
                width: Self.preferredCounterSheetWidth(containerWidth: self.view.bounds.width),
                height: 0
            )
            sheet.delegate = self
            sheet.detents = self.counterSheetDetents()
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            if let selectedDetentIdentifier {
                sheet.selectedDetentIdentifier = selectedDetentIdentifier
                self.counterViewController?.updateAppearance(isMinimized: selectedDetentIdentifier == Constants.minimizedIdentifier)
            }
        }

        if animated {
            sheet.animateChanges(updateSheet)
        } else {
            updateSheet()
        }
    }

    private func counterSheetDetents() -> [UISheetPresentationController.Detent] {
        Self.counterSheetDetentIdentifiers(
            isKeyboardVisible: keyboardOverlapHeight > 0,
            isCompactHeight: traitCollection.verticalSizeClass == .compact
        ).map { identifier in
            switch identifier {
            case Constants.minimizedIdentifier:
                return minimizedDetent()
            case Constants.keyboardTextViewHalfIdentifier:
                return keyboardTextViewHalfDetent()
            case Constants.compactTextViewHalfIdentifier:
                return compactTextViewHalfDetent()
            case .medium:
                return .medium()
            default:
                return .large()
            }
        }
    }

    static func counterSheetDetentIdentifiers(
        isKeyboardVisible: Bool,
        isCompactHeight: Bool = false
    ) -> [UISheetPresentationController.Detent.Identifier] {
        if isKeyboardVisible {
            return [Constants.minimizedIdentifier, Constants.keyboardTextViewHalfIdentifier, .large]
        }

        if isCompactHeight {
            return [Constants.minimizedIdentifier, Constants.compactTextViewHalfIdentifier, .large]
        }

        return [Constants.minimizedIdentifier, .medium, .large]
    }

    static func preferredCounterSheetWidth(containerWidth: CGFloat) -> CGFloat {
        min(max(containerWidth * 0.6, 360), 480)
    }

    private func minimizedDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.minimizedIdentifier) { [weak self] _ in
            let keyboardOverlapHeight = self?.keyboardOverlapHeight ?? 0
            let visibleHeight = keyboardOverlapHeight > 0
                ? Constants.keyboardMinimizedDetentVisibleHeight
                : Constants.minimizedDetentHeight
            return visibleHeight + keyboardOverlapHeight
        }
    }

    private func keyboardTextViewHalfDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.keyboardTextViewHalfIdentifier) { [weak self] context in
            guard let self else {
                return context.maximumDetentValue
            }

            return Self.keyboardTextViewHalfDetentHeight(
                viewHeight: view.bounds.height,
                keyboardOverlapHeight: keyboardOverlapHeight,
                maximumDetentValue: context.maximumDetentValue
            )
        }
    }

    private func compactTextViewHalfDetent() -> UISheetPresentationController.Detent {
        UISheetPresentationController.Detent.custom(identifier: Constants.compactTextViewHalfIdentifier) { context in
            Self.compactTextViewHalfDetentHeight(maximumDetentValue: context.maximumDetentValue)
        }
    }

    static func compactTextViewHalfDetentHeight(maximumDetentValue: CGFloat) -> CGFloat {
        maximumDetentValue / 2
    }

    static func keyboardTextViewHalfDetentHeight(
        viewHeight: CGFloat,
        keyboardOverlapHeight: CGFloat,
        maximumDetentValue: CGFloat
    ) -> CGFloat {
        let availableHeightAboveKeyboard = max(0, viewHeight - keyboardOverlapHeight)
        let visibleHeight = availableHeightAboveKeyboard / 2
        let detentHeight = keyboardOverlapHeight + visibleHeight
        return min(detentHeight, maximumDetentValue)
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
